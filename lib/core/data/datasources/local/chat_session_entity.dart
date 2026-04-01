/// Database entity for chat sessions.
/// Represents a chat session associated with a PDF document.
class ChatSessionEntity {
  /// Unique identifier for the session (UUID)
  final String id;

  /// PDF document ID this session is associated with
  final String pdfId;

  /// PDF title (denormalized for performance)
  final String pdfTitle;

  /// PDF file path (denormalized for performance)
  final String pdfFilePath;

  /// When the session was created (milliseconds since epoch)
  final int createdAt;

  /// When the session was last updated (milliseconds since epoch)
  final int updatedAt;

  /// Total number of messages in the session
  final int messageCount;

  /// Timestamp of the most recent message (milliseconds since epoch)
  final int? lastMessageAt;

  /// Whether the session is archived (soft delete)
  final bool isArchived;

  const ChatSessionEntity({
    required this.id,
    required this.pdfId,
    required this.pdfTitle,
    required this.pdfFilePath,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    this.lastMessageAt,
    required this.isArchived,
  });

  /// Convert from database map (SQLite row)
  factory ChatSessionEntity.fromJson(Map<String, dynamic> json) {
    return ChatSessionEntity(
      id: json['id'] as String,
      pdfId: json['pdf_id'] as String,
      pdfTitle: json['pdf_title'] as String,
      pdfFilePath: json['pdf_file_path'] as String,
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int,
      messageCount: json['message_count'] as int,
      lastMessageAt: json['last_message_at'] as int?,
      isArchived: (json['is_archived'] as int) == 1,
    );
  }

  /// Convert to database map (SQLite row)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pdf_id': pdfId,
      'pdf_title': pdfTitle,
      'pdf_file_path': pdfFilePath,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'message_count': messageCount,
      'last_message_at': lastMessageAt,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  /// Create a copy with updated fields
  ChatSessionEntity copyWith({
    String? id,
    String? pdfId,
    String? pdfTitle,
    String? pdfFilePath,
    int? createdAt,
    int? updatedAt,
    int? messageCount,
    int? lastMessageAt,
    bool? isArchived,
  }) {
    return ChatSessionEntity(
      id: id ?? this.id,
      pdfId: pdfId ?? this.pdfId,
      pdfTitle: pdfTitle ?? this.pdfTitle,
      pdfFilePath: pdfFilePath ?? this.pdfFilePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  /// Convert createdAt timestamp to DateTime
  DateTime get createdAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(createdAt);

  /// Convert updatedAt timestamp to DateTime
  DateTime get updatedAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(updatedAt);

  /// Convert lastMessageAt timestamp to DateTime, or null if not set
  DateTime? get lastMessageAtDateTime => lastMessageAt != null
      ? DateTime.fromMillisecondsSinceEpoch(lastMessageAt!)
      : null;
}
