/// Database entity for chat messages.
/// Represents individual messages within a chat session.
class ChatMessageEntity {
  /// Unique identifier for the message (UUID)
  final String id;

  /// Parent session ID this message belongs to
  final String sessionId;

  /// Message text content
  final String content;

  /// Whether this is a user message (true) or AI message (false)
  final bool isUser;

  /// When the message was created (milliseconds since epoch)
  final int timestamp;

  /// Whether the message is currently being processed
  final bool isProcessing;

  /// Error message if processing failed
  final String? error;

  /// Order of this message within the session
  final int sequenceNumber;

  /// When the message was inserted into database (milliseconds since epoch)
  final int createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.isProcessing,
    this.error,
    required this.sequenceNumber,
    required this.createdAt,
  });

  /// Convert from database map (SQLite row)
  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return ChatMessageEntity(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      content: json['content'] as String,
      isUser: (json['is_user'] as int) == 1,
      timestamp: json['timestamp'] as int,
      isProcessing: (json['is_processing'] as int) == 1,
      error: json['error'] as String?,
      sequenceNumber: json['sequence_number'] as int,
      createdAt: json['created_at'] as int,
    );
  }

  /// Convert to database map (SQLite row)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'content': content,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp,
      'is_processing': isProcessing ? 1 : 0,
      'error': error,
      'sequence_number': sequenceNumber,
      'created_at': createdAt,
    };
  }

  /// Create a copy with updated fields
  ChatMessageEntity copyWith({
    String? id,
    String? sessionId,
    String? content,
    bool? isUser,
    int? timestamp,
    bool? isProcessing,
    String? error,
    int? sequenceNumber,
    int? createdAt,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert timestamp to DateTime
  DateTime get timestampDateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// Convert createdAt to DateTime
  DateTime get createdAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(createdAt);
}
