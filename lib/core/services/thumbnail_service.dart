import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:synchronized/synchronized.dart';

import '../utils/logger.dart';

/// Data class for thumbnail set results
class ThumbnailSet {
  final String? smallPath;
  final String? largePath;

  const ThumbnailSet({this.smallPath, this.largePath});

  bool get hasSmall => smallPath != null;
  bool get hasLarge => largePath != null;
  bool get hasBoth => smallPath != null && largePath != null;

  @override
  String toString() =>
      'ThumbnailSet(small: $smallPath, large: $largePath)';
}

/// Result of a retry operation
class RetryResult {
  final int total;
  final int succeeded;
  final int failed;

  const RetryResult({
    required this.total,
    required this.succeeded,
    required this.failed,
  });

  bool get hasFailures => failed > 0;
  bool get allSucceeded => failed == 0 && total > 0;
  double get successRate => total > 0 ? succeeded / total : 0.0;

  @override
  String toString() =>
      'RetryResult(total: $total, succeeded: $succeeded, failed: $failed, rate: ${(successRate * 100).toStringAsFixed(0)}%)';
}

/// Service for generating PDF thumbnails
class ThumbnailService {
  static const String _cacheDir = 'pdf_thumbnails';
  static const int _maxRetries = 1;

  // Thread-safe failed thumbnail tracking (size-specific)
  // Key format: "pdfPath_widthxheight" → size-specific tracking
  static final Set<String> _failedThumbnails = {};
  static final Lock _lock = Lock();

  /// Generate thumbnail from first page of PDF
  ///
  /// Returns the path to the generated thumbnail image, or null if generation fails.
  ///
  /// Implements retry mechanism for transient errors and tracks failed thumbnails.
  Future<String?> generateThumbnail(
    String pdfPath, {
    int width = 200,
    int height = 280,
  }) async {
    final stopwatch = Stopwatch()..start();
    String? pdfFileName;

    try {
      // Extract filename for logging
      pdfFileName = pdfPath.split('/').last;

      await _logThumbnailEvent('thumbnail_generation_start', {
        'pdf_path': pdfPath,
        'pdf_name': pdfFileName,
        'requested_width': width,
        'requested_height': height,
      });

      // Check if this specific size is in failed set
      final failedKey = _failedKey(pdfPath, width, height);
      if (_failedThumbnails.contains(failedKey)) {
        return null;
      }

      // Get cache directory
      final cacheDir = await getApplicationCacheDirectory();
      final thumbnailsDir = Directory('${cacheDir.path}/$_cacheDir');
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
        await _logThumbnailEvent('thumbnails_dir_created', {
          'path': thumbnailsDir.path,
        });
      }

      // A1: Generate size-specific filename from PDF path hash + dimensions
      final hash = '${pdfPath}_${width}x$height'.hashCode;
      final fileName = 'thumb_${hash.abs()}.png';
      final thumbnailPath = '${thumbnailsDir.path}/$fileName';

      // Check if thumbnail already exists with VALIDATION
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        final fileSize = await thumbnailFile.length();

        if (fileSize > 0) {
          // A4: Validate PNG is readable (check PNG header)
          try {
            final bytes = await thumbnailFile.readAsBytes();
            if (bytes.length > 8) {
              // PNG signature: 0x89 0x50 0x4E 0x47 0x0D 0x0A 0x1A 0x0A
              if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
                stopwatch.stop();
                AppLogger.i(
                  '[ThumbnailService] Cache HIT: $thumbnailPath ($fileSize bytes) '
                  'in ${stopwatch.elapsedMilliseconds}ms',
                );
                await _logThumbnailEvent('thumbnail_cache_hit', {
                  'pdf_name': pdfFileName,
                  'thumbnail_path': thumbnailPath,
                  'file_size': fileSize,
                  'elapsed_ms': stopwatch.elapsedMilliseconds,
                });
                // Remove from failed set if previously failed
                _setFailed(pdfPath, width, height, false);
                return thumbnailPath;
              } else {
                AppLogger.w(
                  '[ThumbnailService] Invalid PNG signature, regenerating: $thumbnailPath',
                );
                await thumbnailFile.delete();
              }
            } else {
              // File too small to be valid PNG
              AppLogger.w(
                '[ThumbnailService] File too small (${bytes.length} bytes), regenerating: $thumbnailPath',
              );
              await thumbnailFile.delete();
            }
          } catch (e) {
            // File exists but unreadable - delete and regenerate
            AppLogger.w(
              '[ThumbnailService] Unreadable thumbnail file, regenerating: $thumbnailPath. Error: $e',
            );
            await thumbnailFile.delete();
          }
        } else {
          // Empty file - delete and regenerate
          AppLogger.w('[ThumbnailService] Empty cached file, regenerating: $thumbnailPath');
          await _logThumbnailEvent('thumbnail_cache_empty', {
            'pdf_name': pdfFileName,
            'thumbnail_path': thumbnailPath,
          });
          await thumbnailFile.delete();
        }
      }

      // Verify PDF file exists before opening
      final pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        AppLogger.e('[ThumbnailService] PDF file does not exist: $pdfPath');
        await _logThumbnailEvent('pdf_file_not_found', {
          'pdf_path': pdfPath,
          'pdf_name': pdfFileName,
        });
        _setFailed(pdfPath, width, height, true);
        return null;
      }

      // Log PDF file size
      final pdfFileSize = await pdfFile.length();
      await _logThumbnailEvent('pdf_file_found', {
        'pdf_name': pdfFileName,
        'pdf_size_bytes': pdfFileSize,
      });

      AppLogger.i('[ThumbnailService] Generating thumbnail for: $pdfPath');
      await _logThumbnailEvent('thumbnail_generation_started', {
        'pdf_name': pdfFileName,
        'thumbnail_path': thumbnailPath,
      });

      // A4: === RETRY LOOP START ===
      PdfDocument? pdf;

      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        final attemptStopwatch = Stopwatch()..start();

        try {
          pdf = await PdfDocument.openFile(pdfPath);

          final page = await pdf.getPage(1); // First page (1-indexed)

          final image = await page.render(
            width: width.toDouble(),
            height: height.toDouble(),
            format: PdfPageImageFormat.png,
          );

          attemptStopwatch.stop();

          if (image == null) {
            throw Exception('Render returned null');
          }

          await thumbnailFile.writeAsBytes(image.bytes);

          // CRITICAL: Store the path before any cleanup operations that might fail
          final successfulPath = thumbnailPath;

          // Cleanup operations - don't let failures prevent returning the path
          try {
            await pdf.close();
          } catch (e) {
            AppLogger.w('[ThumbnailService] Failed to close PDF: $e');
          }
          pdf = null;

          // Success - remove from failed set (don't let failure prevent return)
          try {
            _setFailed(pdfPath, width, height, false);
          } catch (e) {
            AppLogger.w('[ThumbnailService] Failed to update failed set: $e');
          }
          stopwatch.stop();

          // Log success - don't let failure prevent return
          try {
            AppLogger.i(
              '[ThumbnailService] ✓ Thumbnail generated successfully: $successfulPath '
              '(${image.bytes.length} bytes) in ${stopwatch.elapsedMilliseconds}ms '
              '(attempt ${attempt + 1})',
            );
          } catch (e) {
            AppLogger.w('[ThumbnailService] Failed to log success: $e');
          }

          try {
            await _logThumbnailEvent('thumbnail_generated', {
              'pdf_name': pdfFileName,
              'thumbnail_path': successfulPath,
              'file_size': image.bytes.length,
              'image_bytes_length': image.bytes.length,
              'total_elapsed_ms': stopwatch.elapsedMilliseconds,
              'attempts': attempt + 1,
            });
          } catch (e) {
            AppLogger.w('[ThumbnailService] Failed to log thumbnail event: $e');
          }

          return successfulPath;

        } catch (e, st) {
          // Clean up PDF document if open
          try {
            await pdf?.close();
          } catch (_) {}

          AppLogger.e(
            '[ThumbnailService] ✗ Attempt ${attempt + 1} failed: $e',
          );

          // A4: Check if error is retryable
          if (!_isRetryableError(e, st)) {
            // Fatal error - don't retry
            AppLogger.e(
              '[ThumbnailService] Fatal error detected, not retrying: ${e.runtimeType}',
            );
            _setFailed(pdfPath, width, height, true);
            await _logThumbnailError('thumbnail_fatal_error', e, st, {
              'pdf_path': pdfPath,
              'pdf_name': pdfFileName,
              'error_type': 'fatal',
              'error_class': e.runtimeType.toString(),
            });
            return null;
          }

          // Last attempt - give up
          if (attempt >= _maxRetries) {
            AppLogger.e('[ThumbnailService] Max retries reached, giving up');
            _setFailed(pdfPath, width, height, true);
            await _logThumbnailError('thumbnail_generation_failed', e, st, {
              'pdf_path': pdfPath,
              'pdf_name': pdfFileName,
              'attempts': attempt + 1,
              'total_attempts': _maxRetries + 1,
              'error_class': e.runtimeType.toString(),
            });
            return null;
          }

          // Wait before retry
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      // === RETRY LOOP END ===

    } catch (e, st) {
      stopwatch.stop();
      _setFailed(pdfPath, width, height, true);
      AppLogger.e(
        '[ThumbnailService] Unexpected error: $e',
      );

      await _logThumbnailError('thumbnail_generation_exception', e, st, {
        'pdf_path': pdfPath,
        'pdf_name': pdfFileName ?? 'unknown',
        'width': width,
        'height': height,
        'elapsed_ms': stopwatch.elapsedMilliseconds,
        'error_class': e.runtimeType.toString(),
      });

      return null;
    }

    return null;
  }

  /// A3: Generate both small and large thumbnails for a PDF
  ///
  /// Returns ThumbnailSet with paths to both thumbnails.
  /// If one fails, continues to generate the other.
  Future<ThumbnailSet> generateAllSizes(String pdfPath) async {
    AppLogger.i('[ThumbnailService] Generating all thumbnail sizes for: $pdfPath');

    final results = await Future.wait([
      generateThumbnail(pdfPath, width: 112, height: 112),
      generateThumbnail(pdfPath, width: 320, height: 426),
    ]);

    final result = ThumbnailSet(
      smallPath: results[0],
      largePath: results[1],
    );

    AppLogger.i(
      '[ThumbnailService] All sizes complete: small=${result.hasSmall}, large=${result.hasLarge}',
    );

    return result;
  }

  /// A4: Check if an error is retryable
  ///
  /// Fatal errors (file not found, corrupted PDF) should not be retried.
  /// Transient errors (memory, file lock) should be retried.
  bool _isRetryableError(Object error, StackTrace stackTrace) {
    // File not found - fatal
    if (error is FileSystemException) {
      final errorCode = error.osError?.errorCode;
      if (errorCode == 2) {
        // ENOENT - No such file or directory
        return false;
      }
    }

    // PDF corrupted/invalid - fatal
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('invalid pdf') ||
        errorStr.contains('corrupted') ||
        errorStr.contains('format') ||
        errorStr.contains('not a pdf')) {
      return false;
    }

    // Permission denied - could be transient or fatal, retry once
    if (error is FileSystemException && errorStr.contains('permission')) {
      return true;
    }

    // Out of memory - retryable (might work with smaller size)
    if (errorStr.contains('out of memory') ||
        errorStr.contains('oom') ||
        errorStr.contains('memory')) {
      return true;
    }

    // Default - retry for unknown errors
    return true;
  }

  /// A4: Generate a size-specific failed key
  String _failedKey(String pdfPath, int width, int height) {
    return '${pdfPath}_${width}x$height';
  }

  /// A4: Check if this specific size/thumbnail is in failed set
  bool _isFailed(String pdfPath, int width, int height) {
    final key = _failedKey(pdfPath, width, height);
    return _failedThumbnails.contains(key);
  }

  /// A4: Mark a thumbnail as failed or remove from failed set
  void _setFailed(String pdfPath, int width, int height, bool failed) {
    _lock.synchronized(() {
      final key = _failedKey(pdfPath, width, height);
      if (failed) {
        _failedThumbnails.add(key);
      } else {
        _failedThumbnails.remove(key);
      }
    });
  }

  /// Generate small thumbnail for list items (56x56 display, 112x112 render)
  Future<String?> generateSmallThumbnail(String pdfPath) async {
    final result = await generateThumbnail(pdfPath, width: 112, height: 112);
    if (result == null) {
      AppLogger.w('[ThumbnailService] ✗ Failed to generate SMALL thumbnail for: $pdfPath');
    } else {
      AppLogger.i('[ThumbnailService] ✓ Small thumbnail generated successfully');
    }
    return result;
  }

  /// Generate large thumbnail for cards (160x213 display, 320x426 render)
  Future<String?> generateLargeThumbnail(String pdfPath) async {
    final result = await generateThumbnail(pdfPath, width: 320, height: 426);
    if (result == null) {
      AppLogger.w('[ThumbnailService] ✗ Failed to generate LARGE thumbnail for: $pdfPath');
    } else {
      AppLogger.i('[ThumbnailService] ✓ Large thumbnail generated successfully');
    }
    return result;
  }

  /// A4: Retry all previously failed thumbnails
  ///
  /// Returns [RetryResult] with counts of succeeded/failed retries.
  /// Only retries thumbnails that had retryable errors.
  Future<RetryResult> retryFailedThumbnails() async {
    return _lock.synchronized(() async {
      if (_failedThumbnails.isEmpty) {
        AppLogger.i('[ThumbnailService] No failed thumbnails to retry');
        return RetryResult(total: 0, succeeded: 0, failed: 0);
      }

      final toRetry = List<String>.from(_failedThumbnails);
      _failedThumbnails.clear();

      AppLogger.i('[ThumbnailService] Retrying ${toRetry.length} failed thumbnails');

      int succeeded = 0;
      int failed = 0;

      for (final key in toRetry) {
        // Parse key back to pdfPath and size
        // Format: "pdfPath_widthxheight"
        final parts = key.split('_');
        if (parts.length < 3) {
          AppLogger.w('[ThumbnailService] Invalid failed key format: $key');
          continue;
        }

        final sizeParts = parts.last.split('x');
        if (sizeParts.length != 2) {
          AppLogger.w('[ThumbnailService] Invalid size format in key: $key');
          continue;
        }

        final pdfPath = parts.sublist(0, parts.length - 1).join('_');
        final width = int.tryParse(sizeParts[0]);
        final height = int.tryParse(sizeParts[1]);

        if (width == null || height == null) {
          AppLogger.w('[ThumbnailService] Could not parse size from key: $key');
          continue;
        }

        final result = await generateThumbnail(
          pdfPath,
          width: width,
          height: height,
        );

        if (result != null) {
          succeeded++;
          AppLogger.i('[ThumbnailService] ✓ Retry succeeded: $key');
        } else {
          failed++;
          _failedThumbnails.add(key);
          AppLogger.w('[ThumbnailService] ✗ Retry failed for: $key');
        }
      }

      final result = RetryResult(
        total: toRetry.length,
        succeeded: succeeded,
        failed: failed,
      );

      AppLogger.i('[ThumbnailService] Retry complete: $result');
      return result;
    });
  }

  /// A4: Get list of currently failed thumbnail keys
  Future<List<String>> getFailedThumbnails() async {
    return _lock.synchronized(() {
      return List.unmodifiable(_failedThumbnails);
    });
  }

  /// A4: Get count of failed thumbnails
  Future<int> get failedThumbnailCount async {
    return _lock.synchronized(() => _failedThumbnails.length);
  }

  /// A4: Clear the failed thumbnails tracking
  Future<void> clearFailedThumbnails() async {
    return _lock.synchronized(() {
      final count = _failedThumbnails.length;
      _failedThumbnails.clear();
      AppLogger.i('[ThumbnailService] Cleared $count failed thumbnail entries');
    });
  }

  /// A4: Check if a specific thumbnail size is in failed set
  Future<bool> hasFailedThumbnail(String pdfPath, int width, int height) async {
    return _lock.synchronized(() {
      return _isFailed(pdfPath, width, height);
    });
  }

  /// Clear all cached thumbnails
  Future<void> clearCache() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final thumbnailsDir = Directory('${cacheDir.path}/$_cacheDir');
      if (await thumbnailsDir.exists()) {
        await thumbnailsDir.delete(recursive: true);
        AppLogger.i('[ThumbnailService] Cache cleared');
      }
    } catch (e) {
      AppLogger.e('[ThumbnailService] Failed to clear cache', e);
    }
  }

  /// Check if a thumbnail exists for the given PDF path
  @Deprecated('Use getThumbnailPath() with size parameters instead')
  Future<bool> hasThumbnail(String pdfPath) async {
    try {
      final path = await getThumbnailPath(pdfPath, width: 200, height: 280);
      return path != null;
    } catch (e) {
      return false;
    }
  }

  /// Get thumbnail path for a PDF (without generating)
  Future<String?> getThumbnailPath(
    String pdfPath, {
    int width = 200,
    int height = 280,
  }) async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final hash = '${pdfPath}_${width}x$height'.hashCode;
      final fileName = 'thumb_${hash.abs()}.png';
      final thumbnailPath = '${cacheDir.path}/$_cacheDir/$fileName';
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        return thumbnailPath;
      }
      return null;
    } catch (e) {
      AppLogger.e('[ThumbnailService] Failed to get thumbnail path', e);
      return null;
    }
  }

  /// A5: Clean up orphaned thumbnail files
  ///
  /// Removes thumbnail files whose original PDFs no longer exist.
  /// Returns number of files cleaned up.
  Future<int> cleanupOrphanedThumbnails(List<String> activePdfPaths) async {
    final cacheDir = await getApplicationCacheDirectory();
    final thumbnailsDir = Directory('${cacheDir.path}/$_cacheDir');

    if (!await thumbnailsDir.exists()) {
      AppLogger.w('[ThumbnailService] Cache directory does not exist, nothing to cleanup');
      return 0;
    }

    AppLogger.i('[ThumbnailService] Starting orphaned thumbnail cleanup...');

    int cleaned = 0;
    int checked = 0;
    final files = thumbnailsDir.listSync();

    for (final file in files) {
      if (file is! File) continue;

      final name = file.uri.pathSegments.last;
      if (!name.startsWith('thumb_') || !name.endsWith('.png')) continue;

      checked++;

      // Check if any active PDF matches this thumbnail
      bool isOrphan = true;

      for (final pdfPath in activePdfPaths) {
        // Check all possible sizes
        for (final size in ['112x112', '200x280', '320x426']) {
          final expectedHash = '${pdfPath}_$size'.hashCode.abs();
          if (name.contains('thumb_$expectedHash')) {
            isOrphan = false;
            break;
          }
        }
        if (!isOrphan) break;
      }

      if (isOrphan) {
        try {
          await file.delete();
          cleaned++;
        } catch (e) {
          AppLogger.e('[ThumbnailService] Failed to delete orphaned thumbnail: $name', e);
        }
      }
    }

    AppLogger.i(
      '[ThumbnailService] Cleanup complete: $cleaned/$checked orphaned thumbnails deleted',
    );

    return cleaned;
  }

  /// A5: Get total cache size in bytes
  Future<int> getCacheSize() async {
    final cacheDir = await getApplicationCacheDirectory();
    final thumbnailsDir = Directory('${cacheDir.path}/$_cacheDir');

    if (!await thumbnailsDir.exists()) return 0;

    int totalSize = 0;
    final files = thumbnailsDir.listSync();

    for (final file in files) {
      if (file is File) {
        try {
          totalSize += await file.length();
        } catch (_) {}
      }
    }

    return totalSize;
  }

  /// A5: Format cache size for display
  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Log thumbnail event to Crashlytics (only in release mode)
  Future<void> _logThumbnailEvent(
    String eventName,
    Map<String, dynamic> data,
  ) async {
    if (kReleaseMode) {
      try {
        final crashlytics = FirebaseCrashlytics.instance;
        await crashlytics.log('[$eventName] ${data.toString()}');
        // Set custom keys for filtering in Crashlytics console
        for (final entry in data.entries) {
          await crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      } catch (_) {
        // Ignore Crashlytics logging errors
      }
    }
  }

  /// Log thumbnail error to Crashlytics
  Future<void> _logThumbnailError(
    String errorName,
    Object error,
    StackTrace stackTrace,
    Map<String, dynamic> data,
  ) async {
    if (kReleaseMode) {
      try {
        final crashlytics = FirebaseCrashlytics.instance;
        await crashlytics.recordError(
          error,
          stackTrace,
          fatal: false,
          information: [
            'Error Name: $errorName',
            ...data.entries.map((e) => '${e.key}: ${e.value}'),
          ],
        );
      } catch (_) {
        // Ignore Crashlytics logging errors
      }
    }
  }
}
