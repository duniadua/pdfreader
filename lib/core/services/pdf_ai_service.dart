import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;
import '../../../core/utils/logger.dart';
import '../../features/reader/presentation/providers/pdf_chat_state.dart';

/// Service for AI-powered PDF interactions using Firebase Genkit.
///
/// Provides text extraction from PDF documents and AI operations
/// including summarization, data extraction, and chat Q&A.
class PdfAIService {
  final FirebaseFunctions _functions;

  /// Maximum characters to send to AI for context
  static const int maxContextChars = 50000;

  /// Maximum pages to extract text from for performance
  static const int maxExtractPages = 50;

  PdfAIService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

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
        final pageText = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
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
    try {
      // Truncate PDF text if too long
      final truncatedText = pdfText.length > maxContextChars
          ? '${pdfText.substring(0, maxContextChars)}\n\n[Content truncated...]'
          : pdfText;

      final result = await _functions.httpsCallable('summarizeFlow').call({
        'pdfText': truncatedText,
      });

      final summary = result.data['summary'] as String?;
      if (summary == null || summary.isEmpty) {
        throw Exception('Empty response from AI service');
      }

      AppLogger.i('Generated summary (${summary.length} chars)');
      return summary;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to generate summary', e, stackTrace);
      throw PdfAiException('Failed to generate summary: $e');
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
    try {
      // Truncate PDF text if too long
      final truncatedText = pdfText.length > maxContextChars
          ? '${pdfText.substring(0, maxContextChars)}\n\n[Content truncated...]'
          : pdfText;

      final result = await _functions.httpsCallable('extractFlow').call({
        'pdfText': truncatedText,
        'prompt': prompt,
      });

      final data = result.data['data'] as String?;
      if (data == null || data.isEmpty) {
        throw Exception('Empty response from AI service');
      }

      AppLogger.i('Extracted data (${data.length} chars)');
      return data;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to extract data', e, stackTrace);
      throw PdfAiException('Failed to extract data: $e');
    }
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
    try {
      // Truncate PDF text if too long
      final truncatedText = pdfText.length > maxContextChars
          ? '${pdfText.substring(0, maxContextChars)}\n\n[Content truncated...]'
          : pdfText;

      // Convert chat history to JSON format
      final historyJson = history
          .map(
            (m) => {
              'role': m.isUser ? 'user' : 'model',
              'content': m.content,
            },
          )
          .toList();

      final result = await _functions.httpsCallable('chatFlow').call({
        'pdfText': truncatedText,
        'question': question,
        'history': historyJson,
      });

      final response = result.data['response'] as String?;
      if (response == null || response.isEmpty) {
        throw Exception('Empty response from AI service');
      }

      AppLogger.i('Chat response received (${response.length} chars)');
      return response;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to chat with document', e, stackTrace);
      throw PdfAiException('Failed to get response: $e');
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
