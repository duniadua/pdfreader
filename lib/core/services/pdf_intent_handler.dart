import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';
import 'package:pdf_reader_app/core/data/providers/repository_providers.dart';
import 'package:pdf_reader_app/core/utils/logger.dart';

part 'pdf_intent_handler.g.dart';

/// Service for handling incoming PDF intents from Android.
///
/// Uses a [Completer] for the initial intent (eliminates polling race
/// conditions) and a broadcast [StreamController] for subsequent intents
/// that arrive while the app is already running.
class PdfIntentHandler {
  static const _channel = MethodChannel(
    'com.pdfreader.pdf_reader_app/pdf_intent',
  );

  final Ref _ref;

  /// Completer for the initial intent path — awaited by [getPendingFilePath].
  Completer<String?> _initCompleter = Completer<String?>();

  /// Broadcast stream for intents that arrive after initialization.
  final StreamController<String> _intentStreamController =
      StreamController<String>.broadcast();

  /// Whether [initialize] has run.
  // ignore: unused_field
  bool _initialized = false;

  /// Large file threshold — skip page count extraction above this size.
  static const int largeFileThreshold = 10 * 1024 * 1024; // 10 MB

  PdfIntentHandler(this._ref);

  /// Broadcast stream of incoming PDF file paths.
  ///
  /// Emits whenever Android sends a new `onNewPdfIntent` while the app is
  /// already running. Subscribe in the root widget to handle subsequent
  /// intents.
  Stream<String> get intentStream => _intentStreamController.stream;

  /// Initialize the intent handler.
  ///
  /// Sets up the MethodChannel handler for subsequent intents and checks for
  /// an initial intent that launched the app.
  Future<void> initialize() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewPdfIntent') {
        final path = call.arguments as String?;
        if (path != null) {
          // Complete the init completer if it hasn't been completed yet.
          if (!_initCompleter.isCompleted) {
            _initCompleter.complete(path);
          }
          // Always emit to stream for subsequent-intent listeners.
          _intentStreamController.add(path);
          AppLogger.i('Received subsequent PDF intent: $path');
        }
      }
    });

    // Check for initial intent (app opened from file manager).
    try {
      final initialPath = await _channel.invokeMethod<String>(
        'getInitialIntent',
      );
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete(initialPath);
      }
      if (initialPath != null) {
        AppLogger.i('Initial PDF intent detected: $initialPath');
      }
    } catch (e, st) {
      AppLogger.e('Failed to get initial intent', e, st);
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete(null);
      }
    }

    _initialized = true;
  }

  /// Get and clear pending file path.
  ///
  /// Awaits the [Completer] for the initial intent instead of polling.
  /// Returns `null` if no intent was received.
  Future<String?> getPendingFilePath() async {
    final path = await _initCompleter.future;
    // Reset completer so future calls don't return stale values.
    _initCompleter = Completer<String?>();
    return path;
  }

  /// Process a PDF file from an intent and navigate to the reader.
  Future<void> handlePdfIntent(
    String filePath,
    void Function(String pdfId) navigateToReader,
  ) async {
    try {
      AppLogger.i('Processing PDF intent: $filePath');

      // Validate file exists.
      final file = File(filePath);
      if (!await file.exists()) {
        AppLogger.e('PDF file does not exist: $filePath');
        return;
      }

      // Validate PDF magic bytes (%PDF-).
      if (!await _isValidPdf(file)) {
        AppLogger.e('File is not a valid PDF: $filePath');
        return;
      }

      // Get file size.
      final fileSize = await file.length();

      // Extract filename with proper URL decoding.
      final filename = _decodeFilename(filePath);

      // Check for duplicate before processing.
      final repository = _ref.read(sharedPreferencesPdfRepositoryProvider);
      final existingPdf = await _findExistingPdf(repository, filePath);
      if (existingPdf != null) {
        // Update lastOpenedAt and navigate to existing entry.
        final updated = existingPdf.copyWith(lastOpenedAt: DateTime.now());
        await repository.updatePdf(updated);
        AppLogger.i(
          'PDF already exists, navigating to existing: ${existingPdf.id}',
        );
        navigateToReader(existingPdf.id);
        return;
      }

      // Extract page count (skip for large files to avoid OOM).
      int totalPages = 0;
      if (fileSize <= largeFileThreshold) {
        try {
          final bytes = await file.readAsBytes();
          final pdfDocument = sync_pdf.PdfDocument(inputBytes: bytes);
          totalPages = pdfDocument.pages.count;
          pdfDocument.dispose();
        } catch (e, st) {
          AppLogger.w('Could not read PDF page count', e, st);
        }
      } else {
        AppLogger.i(
          'Skipping page count for large file '
          '(${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB)',
        );
      }

      // Create PDF document entry.
      final pdfId = DateTime.now().millisecondsSinceEpoch.toString();

      final pdf = PdfDocument(
        id: pdfId,
        title: filename,
        filePath: filePath,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        lastOpenedAt: DateTime.now(),
        totalPages: totalPages,
      );

      // Save to database.
      final result = await repository.addPdf(pdf);

      result.when(
        success: (savedPdf) async {
          AppLogger.i(
            'PDF saved to database: ${savedPdf.title} (${savedPdf.id})',
          );

          // Generate thumbnail in background.
          repository.generateThumbnail(savedPdf.id).then((thumbnailResult) {
            thumbnailResult.when(
              success: (thumbnailPath) {
                if (thumbnailPath != null) {
                  AppLogger.d('Thumbnail generated: $thumbnailPath');
                }
              },
              failure: (error, stackTrace) {
                AppLogger.w('Failed to generate thumbnail', error, stackTrace);
              },
            );
          });

          navigateToReader(savedPdf.id);
        },
        failure: (error, stackTrace) {
          AppLogger.e('Failed to save PDF to database', error, stackTrace);
          // Do NOT navigate with unsaved pdfId — it won't be found by the reader.
        },
      );
    } catch (e, st) {
      AppLogger.e('Failed to handle PDF intent', e, st);
    }
  }

  /// Validate that a file starts with the PDF magic bytes `%PDF-`.
  ///
  /// Uses [RandomAccessFile] to read only the first 5 bytes, avoiding
  /// loading the entire file into memory.
  Future<bool> _isValidPdf(File file) async {
    try {
      final raf = await file.open();
      try {
        final bytes = await raf.read(5);
        const pdfMagic = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
        if (bytes.length < 5) return false;
        for (int i = 0; i < 5; i++) {
          if (bytes[i] != pdfMagic[i]) return false;
        }
        return true;
      } finally {
        await raf.close();
      }
    } catch (e) {
      return false;
    }
  }

  /// Decode a filename from a file path, handling URL-encoded characters.
  ///
  /// Falls back to the raw filename if decoding fails (e.g. a file literally
  /// named `100%done.pdf` where `%d` is not valid percent-encoding).
  String _decodeFilename(String filePath) {
    final raw = filePath.split('/').last;
    try {
      return Uri.decodeComponent(raw);
    } catch (_) {
      return raw;
    }
  }

  /// Find an existing PDF in the repository by its file path.
  Future<PdfDocument?> _findExistingPdf(
    dynamic repository,
    String filePath,
  ) async {
    try {
      final result = await repository.getAllPdfs();
      return result.when(
        success: (pdfs) {
          for (final pdf in pdfs) {
            if (pdf.filePath == filePath) return pdf;
          }
          return null;
        },
        failure: (error, stackTrace) => null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Dispose resources.
  void dispose() {
    _channel.setMethodCallHandler(null);
    _intentStreamController.close();
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete(null);
    }
  }
}

/// Provider for PdfIntentHandler — keeps alive to handle intents throughout
/// the app lifecycle.
@riverpod
PdfIntentHandler pdfIntentHandler(Ref ref) {
  ref.keepAlive();

  final handler = PdfIntentHandler(ref);

  handler.initialize().catchError((error, stackTrace) {
    AppLogger.e('Failed to initialize PDF intent handler', error, stackTrace);
    return Future.value();
  });

  ref.onDispose(() {
    handler.dispose();
  });

  return handler;
}
