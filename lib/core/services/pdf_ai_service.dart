import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;
import '../../../core/utils/logger.dart';
import '../../features/reader/presentation/providers/pdf_chat_state.dart';

/// Error codes from Firebase Functions
class FirebaseErrorCodes {
  static const String unauthenticated = 'unauthenticated';
  static const String invalidArgument = 'invalid-argument';
  static const String resourceExhausted = 'resource-exhausted';
  static const String failedPrecondition = 'failed-precondition';
  static const String notFound = 'not-found';
  static const String internal = 'internal';
}

/// Logging mixin for AI service operations
///
/// Provides consistent logging across AI service methods.
/// Uses debug-only logging for verbose output in development.
mixin AiServiceLogging {
  /// Log authentication check
  void logAuthCheck(FirebaseAuth auth) {
    if (!kDebugMode) return;
    AppLogger.i('🔐 Auth check: ${auth.currentUser?.uid}');
    AppLogger.i('📧 Email: ${auth.currentUser?.email}');
  }

  /// Log authentication failure
  void logAuthFailure() {
    if (!kDebugMode) return;
    AppLogger.e('❌ Authentication required for AI features');
  }

  /// Log operation start
  void logOperationStart(String operation, Map<String, dynamic> metadata) {
    if (!kDebugMode) return;
    final buffer = StringBuffer();
    buffer.writeln('🚀 $operation');
    metadata.forEach((key, value) {
      buffer.writeln('  📊 $key: $value');
    });
    AppLogger.i(buffer.toString().trim());
  }

  /// Log operation success
  void logOperationSuccess(String operation, Map<String, dynamic> metadata) {
    if (!kDebugMode) return;
    final buffer = StringBuffer();
    buffer.writeln('✅ $operation completed');
    metadata.forEach((key, value) {
      buffer.writeln('  📊 $key: $value');
    });
    AppLogger.i(buffer.toString().trim());
  }

  /// Log operation failure
  void logOperationFailure(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    AppLogger.e('❌ $operation failed', error, stackTrace);
    AppLogger.e('Error type: ${error.runtimeType}');
  }

  /// Log cloud function call
  void logCloudFunctionCall(String functionName, Map<String, dynamic> data) {
    if (!kDebugMode) return;
    AppLogger.i('📤 Calling Firebase Cloud Function: $functionName');
    AppLogger.i('🌐 Region: asia-southeast1');
    AppLogger.i('📦 Data keys: ${data.keys.join(", ")}');
  }

  /// Log cloud function response
  void logCloudFunctionResponse(Map<String, dynamic> data) {
    if (!kDebugMode) return;
    AppLogger.i('✅ Cloud Function responded');
    if (data['model'] != null) {
      AppLogger.i('🤖 Model: ${data['model']}');
    }
    AppLogger.i('📦 Response keys: ${data.keys.join(", ")}');
  }
}

/// Service for AI-powered PDF interactions using Firebase Genkit.
///
/// Provides text extraction from PDF documents and AI operations
/// including summarization, data extraction, and chat Q&A.
class PdfAIService with AiServiceLogging {
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  /// Maximum characters to send to AI for context
  static const int maxContextChars = 50000;

  /// Maximum pages to extract text from for performance
  static const int maxExtractPages = 50;

  PdfAIService({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
      _auth = auth ?? FirebaseAuth.instance;

  /// Verifies user is authenticated before calling AI functions
  void _requireAuth() {
    logOperationStart('Authentication check', {
      'hasUser': _auth.currentUser != null,
      'userId': _auth.currentUser?.uid,
    });

    if (_auth.currentUser == null) {
      logAuthFailure();
      throw PdfAiException(
        'Authentication required for AI features. '
        'Current status: Not authenticated. '
        'Action: Please sign in with Google to use PDF AI features like summarization and chat.',
      );
    }

    logAuthCheck(_auth);
  }

  /// Extracts text content from a PDF file.
  ///
  /// Parameters:
  /// - [filePath]: Path to the PDF file
  /// - [maxPages]: Optional maximum number of pages to extract
  /// - [onProgress]: Optional callback for progress updates (current, total)
  ///
  /// Returns the extracted text as a string.
  Future<String> extractTextFromPdf(
    String filePath, {
    int? maxPages,
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ArgumentError('PDF file not found: $filePath');
      }

      final bytes = await file.readAsBytes();
      final document = sync_pdf.PdfDocument(inputBytes: bytes);

      final pageLimit = maxPages ?? maxExtractPages;
      final pageCount = document.pages.count.clamp(0, pageLimit);

      // Use PdfTextExtractor with the document to extract text
      final textExtractor = sync_pdf.PdfTextExtractor(document);
      final buffer = StringBuffer();

      for (int i = 0; i < pageCount; i++) {
        // Extract text from the specific page
        final pageText = textExtractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        buffer.writeln(pageText);
        buffer.writeln(); // Add spacing between pages

        onProgress?.call(i + 1, pageCount);
      }

      document.dispose();

      String extractedText = buffer.toString();

      // Truncate if too long for AI context
      if (extractedText.length > maxContextChars) {
        AppLogger.w(
          'Extracted text (${extractedText.length} chars) exceeds limit, truncating',
        );
        extractedText = extractedText.substring(0, maxContextChars);
        extractedText += '\n\n[Content truncated due to length...]';
      }

      AppLogger.i(
        'Extracted ${extractedText.length} characters from $pageCount pages',
      );

      return extractedText;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to extract text from PDF', e, stackTrace);
      rethrow;
    }
  }

  /// Generates a summary of the PDF content via Genkit flow.
  ///
  /// Parameters:
  /// - [pdfText]: The extracted text content from the PDF
  ///
  /// Returns the generated summary as a string.
  Future<String> generateSummary(String pdfText) async {
    _requireAuth();

    logOperationStart('Generate summary', {
      'inputLength': pdfText.length,
      'maxContextChars': maxContextChars,
    });

    try {
      // Truncate PDF text if too long
      final truncatedText = pdfText.length > maxContextChars
          ? '${pdfText.substring(0, maxContextChars)}\n\n[Content truncated...]'
          : pdfText;

      logCloudFunctionCall('summarizeFlow', {
        'textLength': truncatedText.length,
      });

      // Note: Firebase Auth token is automatically included by the SDK
      final result = await _functions.httpsCallable('summarizeFlow').call({
        'pdfText': truncatedText,
      });

      logCloudFunctionResponse(result.data);

      final summary = result.data['summary'] as String?;
      if (summary == null || summary.isEmpty) {
        AppLogger.e('❌ Empty response from AI service');
        AppLogger.e('❌ Response data: ${result.data}');
        throw PdfAiException(
          'AI service returned empty response. '
          'Response keys: ${result.data.keys.join(", ")}. '
          'Troubleshooting: Check Firebase Functions logs and ensure model is available.',
        );
      }

      logOperationSuccess('Generate summary', {
        'summaryLength': summary.length,
        'preview': summary.length > 100
            ? '${summary.substring(0, 100)}...'
            : summary,
      });

      return summary;
    } catch (e, stackTrace) {
      logOperationFailure('Generate summary', e, stackTrace);

      // Parse Firebase Functions error
      if (e.toString().contains('firebase_functions')) {
        AppLogger.e('❌ Firebase Functions Error detected');
        AppLogger.e('❌ This might be due to:');
        AppLogger.e('❌ 1. Model not available (check Firebase Functions logs)');
        AppLogger.e('❌ 2. Authentication issue (check if user is signed in)');
        AppLogger.e('❌ 3. Region configuration issue');
        AppLogger.e(
          '❌ 4. API key issue (check Google AI API key in Secret Manager)',
        );
      }

      throw PdfAiException(
        'Failed to generate PDF summary. '
        'Error: ${e.runtimeType}: $e. '
        'Action: Check your internet connection, Firebase Functions deployment, and try again.',
      );
    }
  }

  /// Extracts specific data from the PDF content based on a prompt.
  ///
  /// Parameters:
  /// - [pdfText]: The extracted text content from the PDF
  /// - [prompt]: The extraction prompt describing what to extract
  ///
  /// Returns the extracted data as a string.
  Future<String> extractData(String pdfText, String prompt) async {
    _requireAuth();

    AppLogger.i('💡 ========================================');
    AppLogger.i('💡 === EXTRACT DATA START ===');
    AppLogger.i('💡 ========================================');
    AppLogger.i('📅 Timestamp: ${DateTime.now().toIso8601String()}');
    AppLogger.i('📄 PDF text length: ${pdfText.length} chars');
    AppLogger.i('📝 Extraction prompt: $prompt');

    try {
      // Truncate PDF text if too long
      final truncatedText = pdfText.length > maxContextChars
          ? '${pdfText.substring(0, maxContextChars)}\n\n[Content truncated...]'
          : pdfText;

      AppLogger.i('✂️  Truncated text length: ${truncatedText.length} chars');
      AppLogger.i('📤 Calling Firebase Cloud Function: extractFlow');

      // Note: Firebase Auth token is automatically included by the SDK
      final result = await _functions.httpsCallable('extractFlow').call({
        'pdfText': truncatedText,
        'prompt': prompt,
      });

      AppLogger.i('✅ Cloud Function called successfully');

      if (result.data['model'] != null) {
        AppLogger.i('🤖 Model used: ${result.data['model']}');
      }

      final data = result.data['data'] as String?;
      if (data == null || data.isEmpty) {
        AppLogger.e('❌ Empty response from AI service');
        throw PdfAiException(
          'AI service returned empty data for extraction. '
          'Response keys: ${result.data.keys.join(", ")}. '
          'Troubleshooting: Verify the extraction prompt is valid and model is available.',
        );
      }

      AppLogger.i('✅ Data extracted successfully');
      AppLogger.i('📊 Extracted data length: ${data.length} chars');
      AppLogger.i('📝 Extracted data preview: ${data.substring(0, 100)}...');
      AppLogger.i('💡 ========================================');
      AppLogger.i('💡 ✅ DATA EXTRACTION COMPLETED!');
      AppLogger.i('💡 ========================================');

      return data;
    } catch (e, stackTrace) {
      AppLogger.e('❌ ========================================');
      AppLogger.e('❌ === DATA EXTRACTION FAILED ===');
      AppLogger.e('❌ ========================================');
      AppLogger.e('❌ Error type: ${e.runtimeType}');
      AppLogger.e('❌ Error message: $e');
      AppLogger.e('❌ Stack trace: ${stackTrace.toString()}');
      AppLogger.e('💡 ========================================');
      throw PdfAiException(
        'Failed to extract data from PDF. '
        'Error: ${e.runtimeType}: $e. '
        'Action: Check the extraction prompt format and try again.',
      );
    }
  }

  /// Parse Firebase Functions error and extract user-friendly message
  PdfAiException _parseFirebaseError(Object error) {
    if (error is FirebaseFunctionsException) {
      final code = error.code;
      final message = error.message;
      final details = error.details;

      AppLogger.e('🔴 Firebase Functions Error');
      AppLogger.e('  Code: $code');
      AppLogger.e('  Message: $message');
      AppLogger.e('  Details: $details');

      // Extract the detailed message from the server
      // The server now provides user-friendly error messages with emojis
      String userMessage = message ?? 'An unknown error occurred';

      // Add context based on error code
      switch (code) {
        case FirebaseErrorCodes.resourceExhausted:
          // Rate limit error - message already contains detailed info
          return PdfAiException(userMessage);

        case FirebaseErrorCodes.invalidArgument:
          // Validation error - message already contains details
          return PdfAiException(userMessage);

        case FirebaseErrorCodes.unauthenticated:
          return PdfAiException(
            '🔐 Authentication required\n\n'
            'Please sign in to use PDF AI features.\n\n'
            'Your session may have expired. Please sign in again.',
          );

        case FirebaseErrorCodes.failedPrecondition:
          // API key or configuration issue
          return PdfAiException(
            '⚙️ Service temporarily unavailable\n\n'
            'The AI service is not properly configured. '
            'Please try again in a few minutes or contact support if the issue persists.',
          );

        case FirebaseErrorCodes.notFound:
          return PdfAiException(
            '🤖 AI model not available\n\n'
            'The AI service is currently unavailable. '
            'Please try again in a few minutes.',
          );

        case FirebaseErrorCodes.internal:
          return PdfAiException(
            '💥 Something went wrong\n\n'
            'An unexpected error occurred. Please try again.\n\n'
            'If this keeps happening, please contact support with error details.',
          );

        default:
          return PdfAiException(userMessage);
      }
    }

    // Not a Firebase Functions error
    return PdfAiException(
      'Failed to get AI chat response. '
      'Error: ${error.runtimeType}: $error. '
      'Action: Verify your question is clear and try again.',
    );
  }

  /// Sends a question about the PDF content and receives an AI response.
  ///
  /// Parameters:
  /// - [pdfText]: The extracted text content from the PDF
  /// - [question]: The user's question
  /// - [history]: Optional chat history for context
  ///
  /// Returns the AI response as a string.
  Future<String> chatWithDocument(
    String pdfText,
    String question,
    List<ChatMessage> history,
  ) async {
    _requireAuth();

    AppLogger.i('💡 ========================================');
    AppLogger.i('💡 === CHAT WITH DOCUMENT START ===');
    AppLogger.i('💡 ========================================');
    AppLogger.i('📅 Timestamp: ${DateTime.now().toIso8601String()}');
    AppLogger.i('📄 PDF text length: ${pdfText.length} chars');
    AppLogger.i('❓ User question: $question');
    AppLogger.i('💬 Chat history length: ${history.length} messages');

    try {
      // Truncate PDF text if too long
      final truncatedText = pdfText.length > maxContextChars
          ? '${pdfText.substring(0, maxContextChars)}\n\n[Content truncated...]'
          : pdfText;

      AppLogger.i('✂️  Truncated text length: ${truncatedText.length} chars');

      // Filter history to only include actual chat messages (exclude summary/keypoints)
      // Only include messages where user asked a question, not "Generate summary" etc.
      final filteredHistory = history.where((msg) {
        // Include user messages that look like actual questions (not quick actions)
        if (msg.isUser) {
          final content = msg.content.toLowerCase().trim();
          // Exclude quick action messages
          if (content.startsWith('generate a summary') ||
              content.startsWith('what are the key points') ||
              content.startsWith('extract and summarize')) {
            return false;
          }
          // Include if it's a question or actual chat
          return content.contains('?') ||
              content.length < 200; // Short messages are likely questions
        }
        // Only include assistant responses that are actual chat (not summaries)
        if (!msg.isUser) {
          final content = msg.content.toLowerCase();
          // Exclude summary/keypoint responses (they start with headings/bullets)
          if (content.startsWith('##') || // Markdown headings
              content.startsWith('summary:') ||
              content.startsWith('key points') ||
              content.startsWith('•')) {
            return false;
          }
          // Exclude very long AI responses (likely summaries/extracts)
          if (content.length > 1000) {
            return false;
          }
        }
        return true;
      }).toList();

      AppLogger.i('📝 Filtered history: ${filteredHistory.length} messages (from ${history.length} total)');

      // Limit to last 10 messages to avoid overwhelming the context
      final limitedHistory = filteredHistory.length > 10
          ? filteredHistory.sublist(filteredHistory.length - 10)
          : filteredHistory;

      AppLogger.i('📝 Sending last ${limitedHistory.length} messages as history');

      // Convert chat history to JSON format
      final historyJson = limitedHistory
          .map(
            (m) => {'role': m.isUser ? 'user' : 'model', 'content': m.content},
          )
          .toList();

      AppLogger.i('📤 Calling Firebase Cloud Function: chatFlow');

      // Note: Firebase Auth token is automatically included by the SDK
      final result = await _functions.httpsCallable('chatFlow').call({
        'pdfText': truncatedText,
        'question': question,
        'history': historyJson,
      });

      AppLogger.i('✅ Cloud Function called successfully');

      if (result.data['model'] != null) {
        AppLogger.i('🤖 Model used: ${result.data['model']}');
      }

      final response = result.data['response'] as String?;
      if (response == null || response.isEmpty) {
        AppLogger.e('❌ Empty response from AI service');
        throw PdfAiException(
          'AI service returned empty chat response. '
          'Response keys: ${result.data.keys.join(", ")}. '
          'Troubleshooting: Check if the question is valid and model is available.',
        );
      }

      AppLogger.i('✅ Chat response generated successfully');
      AppLogger.i('📊 Response length: ${response.length} chars');
      AppLogger.i('📝 Response preview: ${response.substring(0, 100)}...');
      AppLogger.i('💡 ========================================');
      AppLogger.i('💡 ✅ CHAT COMPLETED SUCCESSFULLY!');
      AppLogger.i('💡 ========================================');

      return response;
    } on FirebaseFunctionsException catch (e, stackTrace) {
      logOperationFailure('Chat with document', e, stackTrace);
      throw _parseFirebaseError(e);
    } catch (e, stackTrace) {
      logOperationFailure('Chat with document', e, stackTrace);
      throw PdfAiException(
        'Failed to get AI chat response. '
        'Error: ${e.runtimeType}: $e. '
        'Action: Verify your question is clear and try again.',
      );
    }
  }
}

/// Exception thrown when PDF AI operations fail.
class PdfAiException implements Exception {
  final String message;

  const PdfAiException(this.message);

  @override
  String toString() => 'PdfAiException: $message';
}
