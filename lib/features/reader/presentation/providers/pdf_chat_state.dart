import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdf_chat_state.freezed.dart';

/// Represents a single message in the AI chat conversation.
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    /// Unique identifier for the message
    required String id,

    /// The message content (markdown formatted for AI responses)
    required String content,

    /// Whether this message was sent by the user
    required bool isUser,

    /// When the message was created
    required DateTime timestamp,

    /// Whether this message is currently being processed
    @Default(false) bool isProcessing,

    /// Error message if processing failed
    String? error,
  }) = _ChatMessage;

  /// Creates a user message with generated ID
  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  /// Creates an AI message with generated ID
  factory ChatMessage.ai(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a processing placeholder for user messages
  factory ChatMessage.processing(String userContent) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userContent,
      isUser: true,
      timestamp: DateTime.now(),
      isProcessing: true,
    );
  }
}

/// State for the PDF AI chat panel.
@freezed
class PdfChatState with _$PdfChatState {
  /// Initial state - panel is closed
  const factory PdfChatState.initial() = _PdfChatStateInitial;

  /// Panel is visible and ready for interaction
  const factory PdfChatState.visible({
    /// All messages in the conversation
    @Default([]) List<ChatMessage> messages,

    /// Whether a message/AI operation is currently processing
    @Default(false) bool isLoading,

    /// Whether text is currently being extracted from PDF
    @Default(false) bool isExtractingText,

    /// Current text extraction progress (0.0 to 1.0)
    double? extractProgress,

    /// Error message if an operation failed
    String? error,

    /// The extracted PDF text for AI context
    String? extractedText,

    /// The current PDF file path (persists across provider rebuilds)
    String? currentPdfPath,
  }) = _PdfChatStateVisible;

  /// Panel is hidden/closed
  const factory PdfChatState.hidden() = _PdfChatStateHidden;
}

/// Extension for convenience methods on PdfChatState
extension PdfChatStateX on PdfChatState {
  /// Check if panel is currently visible
  bool get isVisible => this is _PdfChatStateVisible;

  /// Check if panel is currently hidden
  bool get isHidden => this is _PdfChatStateHidden || this is _PdfChatStateInitial;

  /// Returns the messages list if visible, empty list otherwise
  List<ChatMessage> get messages => maybeWhen(
        visible: (messages, _, _, _, _, _, _) => messages,
        orElse: () => const [],
      );

  /// Returns whether currently loading if visible
  bool get isLoading => maybeWhen(
        visible: (_, isLoading, _, _, _, _, _) => isLoading,
        orElse: () => false,
      );

  /// Returns whether currently extracting text if visible
  bool get isExtractingText => maybeWhen(
        visible: (_, _, isExtractingText, _, _, _, _) => isExtractingText,
        orElse: () => false,
      );

  /// Returns the current error if visible and has error
  String? get error => maybeWhen(
        visible: (_, _, _, _, error, _, _) => error,
        orElse: () => null,
      );

  /// Returns the extracted text if available
  String? get extractedText => maybeWhen(
        visible: (_, _, _, _, _, extractedText, _) => extractedText,
        orElse: () => null,
      );

  /// Returns the current PDF path if available
  String? get currentPdfPath => maybeWhen(
        visible: (_, _, _, _, _, _, currentPdfPath) => currentPdfPath,
        orElse: () => null,
      );

  /// Get visible state data or null if not visible
  ({List<ChatMessage> messages, bool isLoading, bool isExtractingText, double? extractProgress, String? error, String? extractedText, String? currentPdfPath})? get asVisible {
    return maybeWhen(
      visible: (messages, isLoading, isExtractingText, extractProgress, error, extractedText, currentPdfPath) =>
          (messages: messages, isLoading: isLoading, isExtractingText: isExtractingText, extractProgress: extractProgress, error: error, extractedText: extractedText, currentPdfPath: currentPdfPath),
      orElse: () => null,
    );
  }
}
