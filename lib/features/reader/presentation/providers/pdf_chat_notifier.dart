import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/data/models/pdf_document.dart';
import '../../../../core/services/pdf_ai_service.dart';
import '../../../../core/utils/logger.dart';
import 'pdf_chat_state.dart';

part 'pdf_chat_notifier.g.dart';

/// Provider for PDF AI service
@riverpod
PdfAIService pdfAIService(PdfAIServiceRef ref) {
  return PdfAIService();
}

/// Provider for PDF chat state management
@riverpod
class PdfChatNotifier extends _$PdfChatNotifier {
  PdfAIService? _aiService;
  String? _currentPdfPath;

  @override
  PdfChatState build(String pdfId) {
    _aiService = ref.watch(pdfAIServiceProvider);
    return const PdfChatState.initial();
  }

  /// Toggle chat panel visibility
  void togglePanel() {
    state = state.isVisible ? const PdfChatState.hidden() : const PdfChatState.visible();
  }

  /// Open the chat panel
  void openPanel() {
    if (!state.isVisible) {
      state = const PdfChatState.visible();
    }
  }

  /// Close the chat panel
  void closePanel() {
    state = const PdfChatState.hidden();
  }

  /// Initialize with PDF document for text extraction
  Future<void> initializeWithPdf(PdfDocument pdf) async {
    if (_currentPdfPath == pdf.filePath && state.extractedText != null) {
      // Already initialized with this PDF
      return;
    }

    _currentPdfPath = pdf.filePath;
    if (!state.isVisible) {
      state = const PdfChatState.visible();
    }
  }

  /// Extract text from the PDF document
  Future<void> extractPdfText(String filePath) async {
    if (!state.isVisible || _aiService == null) {
      return;
    }

    // Update to extracting state
    state = const PdfChatState.visible(
      isExtractingText: true,
      extractProgress: 0.0,
    );

    try {
      double progress = 0.0;
      final text = await _aiService!.extractTextFromPdf(
        filePath,
        onProgress: (current, total) {
          progress = total > 0 ? current / total : 0.0;
          state = PdfChatState.visible(
            isExtractingText: true,
            extractProgress: progress,
          );
        },
      );

      state = PdfChatState.visible(
        extractedText: text,
        extractProgress: 1.0,
      );

      AppLogger.i('PDF text extraction complete: ${text.length} chars');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to extract PDF text', e, stackTrace);
      state = PdfChatState.visible(
        error: 'Failed to extract text from PDF. Please try again.',
      );
    }
  }

  /// Send a message and get AI response
  Future<void> sendMessage(String message) async {
    if (!state.isVisible || _aiService == null) {
      return;
    }

    // Ensure we have extracted text
    if (state.extractedText == null && !state.isExtractingText) {
      // Need to extract text first
      if (_currentPdfPath != null) {
        await extractPdfText(_currentPdfPath!);
      }
    }

    // Add user message
    final userMessage = ChatMessage.user(message);
    final updatedMessages = [...state.messages, userMessage];

    state = PdfChatState.visible(
      messages: updatedMessages,
      isLoading: true,
      extractedText: state.extractedText,
    );

    try {
      final textToUse = state.extractedText ?? '';
      if (textToUse.isEmpty) {
        throw Exception('No PDF content available for analysis');
      }

      final response = await _aiService!.chatWithDocument(
        textToUse,
        message,
        state.messages,
      );

      final aiMessage = ChatMessage.ai(response);
      state = PdfChatState.visible(
        messages: [...updatedMessages, aiMessage],
        extractedText: state.extractedText,
      );

      AppLogger.i('Chat message sent and response received');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to send chat message', e, stackTrace);
      state = PdfChatState.visible(
        messages: updatedMessages,
        error: 'Failed to get response. Please try again.',
        extractedText: state.extractedText,
      );
    }
  }

  /// Generate a quick summary of the PDF
  Future<void> generateSummary() async {
    if (!state.isVisible || _aiService == null) {
      return;
    }

    // Ensure we have extracted text
    if (state.extractedText == null && !state.isExtractingText) {
      if (_currentPdfPath != null) {
        await extractPdfText(_currentPdfPath!);
      }
    }

    // Add a system message showing we're generating summary
    final summaryRequestMessage = ChatMessage.user('Generate a summary of this document');
    final updatedMessages = [...state.messages, summaryRequestMessage];

    state = PdfChatState.visible(
      messages: updatedMessages,
      isLoading: true,
      extractedText: state.extractedText,
    );

    try {
      final textToUse = state.extractedText ?? '';
      if (textToUse.isEmpty) {
        throw Exception('No PDF content available for summary');
      }

      final summary = await _aiService!.generateSummary(textToUse);

      final aiMessage = ChatMessage.ai(summary);
      state = PdfChatState.visible(
        messages: [...updatedMessages, aiMessage],
        extractedText: state.extractedText,
      );

      AppLogger.i('Summary generated successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to generate summary', e, stackTrace);
      state = PdfChatState.visible(
        messages: updatedMessages,
        error: 'Failed to generate summary. Please try again.',
        extractedText: state.extractedText,
      );
    }
  }

  /// Extract key points from the PDF
  Future<void> extractKeyPoints() async {
    if (!state.isVisible || _aiService == null) {
      return;
    }

    // Ensure we have extracted text
    if (state.extractedText == null && !state.isExtractingText) {
      if (_currentPdfPath != null) {
        await extractPdfText(_currentPdfPath!);
      }
    }

    final keyPointsMessage = ChatMessage.user('What are the key points in this document?');
    final updatedMessages = [...state.messages, keyPointsMessage];

    state = PdfChatState.visible(
      messages: updatedMessages,
      isLoading: true,
      extractedText: state.extractedText,
    );

    try {
      final textToUse = state.extractedText ?? '';
      if (textToUse.isEmpty) {
        throw Exception('No PDF content available');
      }

      final keyPoints = await _aiService!.extractData(
        textToUse,
        'Extract and summarize the key points from this document. Present them as a bulleted list.',
      );

      final aiMessage = ChatMessage.ai(keyPoints);
      state = PdfChatState.visible(
        messages: [...updatedMessages, aiMessage],
        extractedText: state.extractedText,
      );

      AppLogger.i('Key points extracted successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to extract key points', e, stackTrace);
      state = PdfChatState.visible(
        messages: updatedMessages,
        error: 'Failed to extract key points. Please try again.',
        extractedText: state.extractedText,
      );
    }
  }

  /// Extract custom data with a prompt
  Future<void> extractCustomData(String prompt) async {
    if (!state.isVisible || _aiService == null) {
      return;
    }

    // Ensure we have extracted text
    if (state.extractedText == null && !state.isExtractingText) {
      if (_currentPdfPath != null) {
        await extractPdfText(_currentPdfPath!);
      }
    }

    final customMessage = ChatMessage.user(prompt);
    final updatedMessages = [...state.messages, customMessage];

    state = PdfChatState.visible(
      messages: updatedMessages,
      isLoading: true,
      extractedText: state.extractedText,
    );

    try {
      final textToUse = state.extractedText ?? '';
      if (textToUse.isEmpty) {
        throw Exception('No PDF content available');
      }

      final result = await _aiService!.extractData(textToUse, prompt);

      final aiMessage = ChatMessage.ai(result);
      state = PdfChatState.visible(
        messages: [...updatedMessages, aiMessage],
        extractedText: state.extractedText,
      );

      AppLogger.i('Custom data extracted successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to extract custom data', e, stackTrace);
      state = PdfChatState.visible(
        messages: updatedMessages,
        error: 'Failed to extract data. Please try again.',
        extractedText: state.extractedText,
      );
    }
  }

  /// Clear all chat messages
  void clearChat() {
    if (!state.isVisible) return;

    state = const PdfChatState.visible();
  }

  /// Dismiss any error message
  void dismissError() {
    if (!state.isVisible) return;

    state = PdfChatState.visible(
      messages: state.messages,
      extractedText: state.extractedText,
    );
  }

  /// Retry the last failed operation
  Future<void> retryLastOperation() async {
    if (!state.isVisible || state.error == null) return;

    // Get the last user message to retry
    final lastUserMessage = state.messages.reversed.where((m) => m.isUser).firstOrNull;
    if (lastUserMessage != null) {
      // Remove the failed messages and retry
      final messagesToKeep = <ChatMessage>[];
      for (final message in state.messages) {
        if (message == lastUserMessage) break;
        messagesToKeep.add(message);
      }

      state = PdfChatState.visible(
        messages: messagesToKeep,
        extractedText: state.extractedText,
      );

      await sendMessage(lastUserMessage.content);
    }
  }
}

/// Extension on List<ChatMessage> to add firstOrNull
extension ChatMessageListX on List<ChatMessage> {
  ChatMessage? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
