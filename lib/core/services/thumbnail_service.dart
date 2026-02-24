import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../utils/logger.dart';

/// Service for generating PDF thumbnails
class ThumbnailService {
  static const String _cacheDir = 'pdf_thumbnails';

  /// Generate thumbnail from first page of PDF
  ///
  /// Returns the path to the generated thumbnail image, or null if generation fails.
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

      // Log thumbnail generation start
      await _logThumbnailEvent('thumbnail_generation_start', {
        'pdf_path': pdfPath,
        'pdf_name': pdfFileName,
        'requested_width': width,
        'requested_height': height,
      });

      // Get cache directory
      final cacheDir = await getApplicationCacheDirectory();
      final thumbnailsDir = Directory('${cacheDir.path}/$_cacheDir');
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
        await _logThumbnailEvent('thumbnails_dir_created', {
          'path': thumbnailsDir.path,
        });
      }

      // Generate unique filename from PDF path hash
      final hash = pdfPath.hashCode;
      final fileName = 'thumb_$hash.png';
      final thumbnailPath = '${thumbnailsDir.path}/$fileName';

      // Check if thumbnail already exists and verify it's valid
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        // Verify file is not empty
        final fileSize = await thumbnailFile.length();
        if (fileSize > 0) {
          stopwatch.stop();
          AppLogger.i('Thumbnail cache hit: $thumbnailPath ($fileSize bytes)');
          await _logThumbnailEvent('thumbnail_cache_hit', {
            'pdf_name': pdfFileName,
            'thumbnail_path': thumbnailPath,
            'file_size': fileSize,
            'elapsed_ms': stopwatch.elapsedMilliseconds,
          });
          return thumbnailPath;
        } else {
          // Delete empty file and regenerate
          AppLogger.w('Cached thumbnail is empty, regenerating: $thumbnailPath');
          await _logThumbnailEvent('thumbnail_cache_empty', {
            'pdf_name': pdfFileName,
            'thumbnail_path': thumbnailPath,
          });
          await thumbnailFile.delete();
        }
      }

      AppLogger.i('Generating thumbnail for: $pdfPath');
      await _logThumbnailEvent('thumbnail_generation_started', {
        'pdf_name': pdfFileName,
        'thumbnail_path': thumbnailPath,
      });

      // Verify PDF file exists before opening
      final pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        AppLogger.e('PDF file does not exist: $pdfPath');
        await _logThumbnailEvent('pdf_file_not_found', {
          'pdf_path': pdfPath,
          'pdf_name': pdfFileName,
        });
        return null;
      }

      // Log PDF file size
      final pdfFileSize = await pdfFile.length();
      await _logThumbnailEvent('pdf_file_found', {
        'pdf_name': pdfFileName,
        'pdf_size_bytes': pdfFileSize,
      });

      // Generate new thumbnail
      final renderStopwatch = Stopwatch()..start();
      final pdf = await PdfDocument.openFile(pdfPath);

      await _logThumbnailEvent('pdf_opened', {
        'pdf_name': pdfFileName,
        'open_elapsed_ms': renderStopwatch.elapsedMilliseconds,
      });

      final page = await pdf.getPage(1); // First page (1-indexed)

      await _logThumbnailEvent('pdf_page_loaded', {
        'pdf_name': pdfFileName,
        'page': 1,
        'elapsed_ms': renderStopwatch.elapsedMilliseconds,
      });

      final image = await page.render(
        width: width.toDouble(),
        height: height.toDouble(),
        format: PdfPageImageFormat.png,
      );

      renderStopwatch.stop();
      await _logThumbnailEvent('pdf_page_rendered', {
        'pdf_name': pdfFileName,
        'render_elapsed_ms': renderStopwatch.elapsedMilliseconds,
      });

      if (image == null) {
        AppLogger.w('Failed to render PDF page for thumbnail: $pdfPath');
        await _logThumbnailEvent('pdf_render_failed', {
          'pdf_name': pdfFileName,
          'width': width,
          'height': height,
        });
        await pdf.close();
        return null;
      }

      await thumbnailFile.writeAsBytes(image.bytes);
      await pdf.close();

      // Verify file was created
      if (await thumbnailFile.exists()) {
        final fileSize = await thumbnailFile.length();
        stopwatch.stop();
        AppLogger.i('Thumbnail generated successfully: $thumbnailPath ($fileSize bytes)');
        await _logThumbnailEvent('thumbnail_generated', {
          'pdf_name': pdfFileName,
          'thumbnail_path': thumbnailPath,
          'file_size': fileSize,
          'image_bytes_length': image.bytes.length,
          'total_elapsed_ms': stopwatch.elapsedMilliseconds,
        });
        return thumbnailPath;
      } else {
        AppLogger.e('Thumbnail file was not created: $thumbnailPath');
        await _logThumbnailEvent('thumbnail_file_not_created', {
          'pdf_name': pdfFileName,
          'thumbnail_path': thumbnailPath,
        });
        return null;
      }
    } catch (e, st) {
      stopwatch.stop();
      AppLogger.e('Failed to generate thumbnail for $pdfPath', e, st);

      // Log error to Crashlytics with custom keys
      await _logThumbnailError('thumbnail_generation_exception', e, st, {
        'pdf_path': pdfPath,
        'pdf_name': pdfFileName ?? 'unknown',
        'width': width,
        'height': height,
        'elapsed_ms': stopwatch.elapsedMilliseconds,
      });

      return null;
    }
  }

  /// Log thumbnail event to Crashlytics (only in release mode)
  Future<void> _logThumbnailEvent(String eventName, Map<String, dynamic> data) async {
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
    // Always log to AppLogger for debug mode
    AppLogger.i('[$eventName] $data');
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

  /// Generate small thumbnail for list items (56x56)
  Future<String?> generateSmallThumbnail(String pdfPath) async {
    return generateThumbnail(pdfPath, width: 112, height: 112);
  }

  /// Generate large thumbnail for cards (160x213)
  Future<String?> generateLargeThumbnail(String pdfPath) async {
    return generateThumbnail(pdfPath, width: 320, height: 426);
  }

  /// Clear all cached thumbnails
  Future<void> clearCache() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final thumbnailsDir = Directory('${cacheDir.path}/$_cacheDir');
      if (await thumbnailsDir.exists()) {
        await thumbnailsDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore errors when clearing cache
    }
  }

  /// Check if a thumbnail exists for the given PDF path
  Future<bool> hasThumbnail(String pdfPath) async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final hash = pdfPath.hashCode;
      final fileName = 'thumb_$hash.png';
      final thumbnailPath = '${cacheDir.path}/$_cacheDir/$fileName';
      final thumbnailFile = File(thumbnailPath);
      return await thumbnailFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get thumbnail path for a PDF (without generating)
  Future<String?> getThumbnailPath(String pdfPath) async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final hash = pdfPath.hashCode;
      final fileName = 'thumb_$hash.png';
      final thumbnailPath = '${cacheDir.path}/$_cacheDir/$fileName';
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        return thumbnailPath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
