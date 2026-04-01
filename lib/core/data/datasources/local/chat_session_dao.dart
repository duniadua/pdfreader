import 'package:sqflite/sqflite.dart';
import 'chat_database.dart';
import 'chat_session_entity.dart';

/// Data Access Object for chat sessions.
/// Provides CRUD operations for the chat_sessions table.
class ChatSessionDao {
  final Database _database;

  ChatSessionDao(this._database);

  /// Insert a new chat session
  Future<ChatSessionEntity> insert(ChatSessionEntity session) async {
    final id = await _database.insert(
      TableNames.chatSessions,
      session.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return session;
  }

  /// Get a session by ID
  Future<ChatSessionEntity?> getById(String id) async {
    final maps = await _database.query(
      TableNames.chatSessions,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ChatSessionEntity.fromJson(maps.first);
  }

  /// Get a session by PDF ID
  Future<ChatSessionEntity?> getByPdfId(String pdfId) async {
    final maps = await _database.query(
      TableNames.chatSessions,
      where: 'pdf_id = ? AND is_archived = 0',
      whereArgs: [pdfId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ChatSessionEntity.fromJson(maps.first);
  }

  /// Get all sessions (non-archived), ordered by most recently updated
  Future<List<ChatSessionEntity>> getAll({
    int limit = 20,
    int offset = 0,
  }) async {
    final maps = await _database.query(
      TableNames.chatSessions,
      where: 'is_archived = 0',
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => ChatSessionEntity.fromJson(map)).toList();
  }

  /// Get recent sessions, ordered by last message time
  Future<List<ChatSessionEntity>> getRecentSessions({int limit = 10}) async {
    final maps = await _database.query(
      TableNames.chatSessions,
      where: 'is_archived = 0',
      orderBy: 'last_message_at DESC',
      limit: limit,
    );
    return maps.map((map) => ChatSessionEntity.fromJson(map)).toList();
  }

  /// Update a session
  Future<int> update(ChatSessionEntity session) async {
    return await _database.update(
      TableNames.chatSessions,
      session.toJson(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Update session metadata (message count and last message time)
  Future<int> updateMetadata({
    required String sessionId,
    required int messageCount,
    int? lastMessageAt,
  }) async {
    final values = <String, dynamic>{
      'message_count': messageCount,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (lastMessageAt != null) {
      values['last_message_at'] = lastMessageAt;
    }
    return await _database.update(
      TableNames.chatSessions,
      values,
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Archive (soft delete) a session
  Future<int> archive(String sessionId) async {
    return await _database.update(
      TableNames.chatSessions,
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Delete a session permanently (cascades to messages)
  Future<int> delete(String sessionId) async {
    return await _database.delete(
      TableNames.chatSessions,
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Delete all archived sessions
  Future<int> deleteArchived() async {
    return await _database.delete(
      TableNames.chatSessions,
      where: 'is_archived = 1',
    );
  }

  /// Count total sessions (non-archived)
  Future<int> count() async {
    final result = await _database.rawQuery(
      'SELECT COUNT(*) as count FROM ${TableNames.chatSessions} WHERE is_archived = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
