import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';
import 'package:pdf_reader_app/core/data/providers/repository_providers.dart';
import 'package:pdf_reader_app/core/utils/logger.dart';

part 'pdf_intent_handler.g.dart';

/// Service for handling incoming PDF intents from Android
class PdfIntentHandler {
  static const _channel = MethodChannel(
    'com.pdfreader.pdf_reader_app/pdf_intent',
  );
  String? _pendingFilePath;
  final Ref _ref;

  PdfIntentHandler(this._ref);

  /// Initialize the intent handler
  Future<void> initialize() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewPdfIntent') {
        _pendingFilePath = call.arguments as String?;
        AppLogger.i('Received PDF intent: $_pendingFilePath');
      }
    });

    // Check for initial intent (app opened from PDF)
    final initialPath = await _channel.invokeMethod<String>('getInitialIntent');
    if (initialPath != null) {
      _pendingFilePath = initialPath;
      AppLogger.i('Initial PDF intent: $initialPath');
    }
  }

  /// Get and clear pending file path
  String? getPendingFilePath() {
    final path = _pendingFilePath;
    _pendingFilePath = null;
    return path;
  }

  /// Process PDF file from intent and navigate to reader
  Future<void> handlePdfIntent(
    String filePath,
    void Function(String pdfId) navigateToReader,
  ) async {
    try {
      AppLogger.i('Processing PDF intent: $filePath');

      // Validate file exists
      final file = File(filePath);
      if (!await file.exists()) {
        AppLogger.e('PDF file does not exist: $filePath');
        return;
      }

      // Get file size
      final fileSize = await file.length();

      // Extract filename from path
      final filename = filePath.split('/').last.replaceAll('%20', ' ');

      // Get total pages from PDF (basic validation)
      int totalPages = 0;
      try {
        // Import syncfusion_pdf to get page count
        final bytes = await file.readAsBytes();
        final pdfDocument = sync_pdf.PdfDocument(inputBytes: bytes);
        totalPages = pdfDocument.pages.count;
        pdfDocument.dispose();
      } catch (e, st) {
        AppLogger.w('Could not read PDF page count, using default', e, st);
        totalPages = 1; // Default to 1 if we can't read
      }

      // Create PDF document entry
      final pdf = PdfDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: filename,
        filePath: filePath,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        lastOpenedAt: DateTime.now(),
        totalPages: totalPages,
      );

      // Save to database via repository
      final repository = _ref.read(pdfRepositoryProvider);
      final result = await repository.addPdf(pdf);

      result.when(
        success: (savedPdf) async {
          AppLogger.i('PDF saved to database: ${savedPdf.id}');

          // Generate thumbnail in background
          repository.generateThumbnail(savedPdf.id).then((thumbnailResult) {
            thumbnailResult.when(
              success: (thumbnailPath) {
                if (thumbnailPath != null) {
                  AppLogger.i('Thumbnail generated: $thumbnailPath');
                }
              },
              failure: (error, stackTrace) {
                AppLogger.w('Failed to generate thumbnail', error, stackTrace);
              },
            );
          });

          // Navigate to reader
          navigateToReader(savedPdf.id);
        },
        failure: (error, stackTrace) {
          AppLogger.e('Failed to save PDF to database', error, stackTrace);
          // Still navigate even if save fails - user can view the PDF
          navigateToReader(pdf.id);
        },
      );
    } catch (e, st) {
      AppLogger.e('Failed to handle PDF intent', e, st);
    }
  }

  /// Dispose resources
  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}

/// Provider for PdfIntentHandler - keeps alive to handle intents throughout app lifecycle
@riverpod
PdfIntentHandler pdfIntentHandler(Ref ref) {
  // Keep alive to prevent disposal when navigating away from screens
  ref.keepAlive();

  final handler = PdfIntentHandler(ref);

  // Initialize the handler when first accessed
  handler.initialize().catchError((error, stackTrace) {
    AppLogger.e('Failed to initialize PDF intent handler', error, stackTrace);
    return Future.value();
  });

  ref.onDispose(() {
    // Cleanup method channel handler
    handler.dispose();
  });

  return handler;
}
