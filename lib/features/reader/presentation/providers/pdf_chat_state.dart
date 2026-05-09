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

    /// Whether this message failed to get a response
    @Default(false) bool isFailed,

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

  /// Creates a failed user message (no AI response received)
  factory ChatMessage.failed(String content, {String? id}) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      isFailed: true,
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

    /// Rate limit information (when user is rate limited)
    RateLimitInfo? rateLimitInfo,
  }) = _PdfChatStateVisible;

  /// Panel is hidden/closed
  const factory PdfChatState.hidden() = _PdfChatStateHidden;
}

/// Rate limit information for showing countdown to users
@freezed
class RateLimitInfo with _$RateLimitInfo {
  const factory RateLimitInfo({
    /// When the rate limit will expire (UTC timestamp)
    required DateTime expiresAt,

    /// Number of seconds until retry is allowed
    required int retryAfterSeconds,

    /// User-friendly error message
    required String message,
  }) = _RateLimitInfo;

  /// Create rate limit info from retry-after seconds
  factory RateLimitInfo.fromSeconds(int seconds, String message) {
    return RateLimitInfo(
      expiresAt: DateTime.now().add(Duration(seconds: seconds)),
      retryAfterSeconds: seconds,
      message: message,
    );
  }
}

/// Extension on RateLimitInfo for computed properties
extension RateLimitInfoX on RateLimitInfo {
  /// Check if rate limit has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get remaining seconds (0 if expired)
  int get remainingSeconds {
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}

/// Extension for convenience methods on PdfChatState
extension PdfChatStateX on PdfChatState {
  /// Check if panel is currently visible
  bool get isVisible => this is _PdfChatStateVisible;

  /// Check if panel is currently hidden
  bool get isHidden =>
      this is _PdfChatStateHidden || this is _PdfChatStateInitial;

  /// Check if user is currently rate limited
  bool get isRateLimited => maybeWhen(
    visible: (_, _, _, _, _, _, _, rateLimitInfo) =>
        rateLimitInfo != null && !rateLimitInfo.isExpired,
    orElse: () => false,
  );

  /// Returns the messages list if visible, empty list otherwise
  List<ChatMessage> get messages => maybeWhen(
    visible: (messages, _, _, _, _, _, _, _) => messages,
    orElse: () => const [],
  );

  /// Returns whether currently loading if visible
  bool get isLoading => maybeWhen(
    visible: (_, isLoading, _, _, _, _, _, _) => isLoading,
    orElse: () => false,
  );

  /// Returns whether currently extracting text if visible
  bool get isExtractingText => maybeWhen(
    visible: (_, _, isExtractingText, _, _, _, _, _) => isExtractingText,
    orElse: () => false,
  );

  /// Returns the current error if visible and has error
  String? get error => maybeWhen(
    visible: (_, _, _, _, error, _, _, _) => error,
    orElse: () => null,
  );

  /// Returns the extracted text if available
  String? get extractedText => maybeWhen(
    visible: (_, _, _, _, _, extractedText, _, _) => extractedText,
    orElse: () => null,
  );

  /// Returns the current PDF path if available
  String? get currentPdfPath => maybeWhen(
    visible: (_, _, _, _, _, _, currentPdfPath, _) => currentPdfPath,
    orElse: () => null,
  );

  /// Returns rate limit info if available and not expired
  RateLimitInfo? get rateLimitInfo => maybeWhen(
    visible: (_, _, _, _, _, _, _, rateLimitInfo) {
      if (rateLimitInfo == null || rateLimitInfo.isExpired) {
        return null;
      }
      return rateLimitInfo;
    },
    orElse: () => null,
  );

  /// Get visible state data or null if not visible
  ({
    List<ChatMessage> messages,
    bool isLoading,
    bool isExtractingText,
    double? extractProgress,
    String? error,
    String? extractedText,
    String? currentPdfPath,
    RateLimitInfo? rateLimitInfo,
  })?
  get asVisible {
    return maybeWhen(
      visible:
          (
            messages,
            isLoading,
            isExtractingText,
            extractProgress,
            error,
            extractedText,
            currentPdfPath,
            rateLimitInfo,
          ) =>
              (
            messages: messages,
            isLoading: isLoading,
            isExtractingText: isExtractingText,
            extractProgress: extractProgress,
            error: error,
            extractedText: extractedText,
            currentPdfPath: currentPdfPath,
            rateLimitInfo: rateLimitInfo,
          ),
      orElse: () => null,
    );
  }
}
