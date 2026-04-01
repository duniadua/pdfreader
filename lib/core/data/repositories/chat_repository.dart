import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/local/chat_database.dart';
import '../../data/datasources/local/chat_session_dao.dart';
import '../../data/datasources/local/chat_message_dao.dart';
import '../../data/datasources/local/chat_session_entity.dart';
import '../../data/datasources/local/chat_message_entity.dart';
import '../../../core/data/models/pdf_document.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/logger.dart';

part 'chat_repository.g.dart';

/// Simple chat message model for repository layer
class RepositoryChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isProcessing;
  final String? error;

  const RepositoryChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.isProcessing,
    this.error,
  });
}

/// Repository interface for chat operations
abstract class ChatRepository {
  /// Get or create a chat session for a PDF
  Future<Result<ChatSessionEntity>> getOrCreateSession(
    String pdfId,
    PdfDocument pdf,
  );

  /// Get a session by PDF ID
  Future<Result<ChatSessionEntity?>> getSessionByPdfId(String pdfId);

  /// Get messages for a session
  Future<Result<List<RepositoryChatMessage>>> getMessages(String sessionId);

  /// Add a message to a session
  Future<Result<ChatMessageEntity>> addMessage(
    String sessionId,
    RepositoryChatMessage message,
  );

  /// Update session metadata (message count, last message time)
  Future<Result<void>> updateSessionMetadata({
    required String sessionId,
    required int messageCount,
    int? lastMessageAt,
  });

  /// Get recent chat sessions
  Future<Result<List<ChatSessionEntity>>> getRecentSessions({int limit});

  /// Delete a session (cascades to messages)
  Future<Result<void>> deleteSession(String sessionId);

  /// Archive a session (soft delete)
  Future<Result<void>> archiveSession(String sessionId);
}

/// SQLite implementation of ChatRepository
class SqliteChatRepository implements ChatRepository {
  final ChatDatabase _chatDatabase;
  ChatSessionDao? _sessionDao;
  ChatMessageDao? _messageDao;

  SqliteChatRepository({required ChatDatabase database})
    : _chatDatabase = database;

  /// Initialize the DAOs (must be called after construction)
  Future<void> _initDaos() async {
    if (_sessionDao != null && _messageDao != null) {
      // Already initialized
      return;
    }
    final db = await _chatDatabase.database;
    _sessionDao = ChatSessionDao(db);
    _messageDao = ChatMessageDao(db);
  }

  /// Ensure DAOs are initialized before use
  Future<void> _ensureInitialized() async {
    if (_sessionDao == null || _messageDao == null) {
      await _initDaos();
    }
  }

  @override
  Future<Result<ChatSessionEntity>> getOrCreateSession(
    String pdfId,
    PdfDocument pdf,
  ) async {
    try {
      await _ensureInitialized();
      // Try to get existing session
      final existingSession = await _sessionDao!.getByPdfId(pdfId);
      if (existingSession != null) {
        return Result.success(existingSession);
      }

      // Create new session
      final now = DateTime.now().millisecondsSinceEpoch;
      final session = ChatSessionEntity(
        id: _generateSessionId(pdfId),
        pdfId: pdfId,
        pdfTitle: pdf.title,
        pdfFilePath: pdf.filePath,
        createdAt: now,
        updatedAt: now,
        messageCount: 0,
        lastMessageAt: null,
        isArchived: false,
      );

      await _sessionDao!.insert(session);
      AppLogger.i('Created new chat session for PDF: ${pdf.title}');
      return Result.success(session);
    } catch (e, st) {
      AppLogger.e('Failed to get or create chat session', e, st);
      return Result.failure(e, st);
    }
  }

  @override
  Future<Result<ChatSessionEntity?>> getSessionByPdfId(String pdfId) async {
    try {
      await _ensureInitialized();
      final session = await _sessionDao!.getByPdfId(pdfId);
      return Result.success(session);
    } catch (e, st) {
      AppLogger.e('Failed to get session by PDF ID', e, st);
      return Result.failure(e, st);
    }
  }

  @override
  Future<Result<List<RepositoryChatMessage>>> getMessages(
    String sessionId,
  ) async {
    try {
      await _ensureInitialized();
      final messageEntities = await _messageDao!.getBySessionId(sessionId);
      final messages = messageEntities.map((entity) {
        return RepositoryChatMessage(
          id: entity.id,
          content: entity.content,
          isUser: entity.isUser,
          timestamp: entity.timestampDateTime,
          isProcessing: entity.isProcessing,
          error: entity.error,
        );
      }).toList();
      return Result.success(messages);
    } catch (e, st) {
      AppLogger.e('Failed to get messages for session', e, st);
      return Result.failure(e, st);
    }
  }

  @override
  Future<Result<ChatMessageEntity>> addMessage(
    String sessionId,
    RepositoryChatMessage message,
  ) async {
    try {
      await _ensureInitialized();
      final seqNumber = await _messageDao!.getNextSequenceNumber(sessionId);
      final now = DateTime.now().millisecondsSinceEpoch;
      final entity = ChatMessageEntity(
        id: message.id,
        sessionId: sessionId,
        content: message.content,
        isUser: message.isUser,
        timestamp: message.timestamp.millisecondsSinceEpoch,
        isProcessing: message.isProcessing,
        error: message.error,
        sequenceNumber: seqNumber,
        createdAt: now,
      );
      await _messageDao!.insert(entity);
      return Result.success(entity);
    } catch (e, st) {
      AppLogger.e('Failed to add message to database', e, st);
      return Result.failure(e, st);
    }
  }

  @override
  Future<Result<void>> updateSessionMetadata({
    required String sessionId,
    required int messageCount,
    int? lastMessageAt,
  }) async {
    try {
      await _ensureInitialized();
      await _sessionDao!.updateMetadata(
        sessionId: sessionId,
        messageCount: messageCount,
        lastMessageAt: lastMessageAt,
      );
      return Result.success(null);
    } catch (e, st) {
      AppLogger.e('Failed to update session metadata', e, st);
      return Result.failure(e, st);
    }
  }

  @override
  Future<Result<List<ChatSessionEntity>>> getRecentSessions({
    int limit = 10,
  }) async {
    try {
      await _ensureInitialized();
      final sessions = await _sessionDao!.getRecentSessions(limit: limit);
      return Result.success(sessions);
    } catch (e, st) {
      AppLogger.e('Failed to get recent sessions', e, st);
      return Result.failure(e, st);
    }
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    try {
      await _sessionDao!.delete(sessionId);
      AppLogger.i('Deleted chat session: $sessionId');
      return Result.success(null);
    } catch (e, st) {
      AppLogger.e('Failed to delete session', e, st);
      return Result.failure(e, st);
    }
  }

  @override
  Future<Result<void>> archiveSession(String sessionId) async {
    try {
      await _ensureInitialized();
      await _sessionDao!.archive(sessionId);
      AppLogger.i('Archived chat session: $sessionId');
      return Result.success(null);
    } catch (e, st) {
      AppLogger.e('Failed to archive session', e, st);
      return Result.failure(e, st);
    }
  }

  /// Generate a unique session ID for a PDF
  String _generateSessionId(String pdfId) {
    return 'chat_${pdfId}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Provider for ChatRepository
@riverpod
ChatRepository chatRepository(Ref ref) {
  return SqliteChatRepository(database: ChatDatabase.instance);
}
