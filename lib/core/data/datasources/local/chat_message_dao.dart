import 'package:sqflite/sqflite.dart';
import 'chat_database.dart';
import 'chat_message_entity.dart';

/// Data Access Object for chat messages.
/// Provides CRUD operations for the chat_messages table.
class ChatMessageDao {
  final Database _database;

  ChatMessageDao(this._database);

  /// Insert a new message
  Future<ChatMessageEntity> insert(ChatMessageEntity message) async {
    await _database.insert(
      TableNames.chatMessages,
      message.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return message;
  }

  /// Insert multiple messages in a transaction
  Future<void> insertBatch(List<ChatMessageEntity> messages) async {
    await _database.transaction((txn) async {
      for (final message in messages) {
        await txn.insert(
          TableNames.chatMessages,
          message.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Get a message by ID
  Future<ChatMessageEntity?> getById(String id) async {
    final maps = await _database.query(
      TableNames.chatMessages,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ChatMessageEntity.fromJson(maps.first);
  }

  /// Get all messages for a session, ordered by sequence number
  Future<List<ChatMessageEntity>> getBySessionId(String sessionId) async {
    final maps = await _database.query(
      TableNames.chatMessages,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sequence_number ASC',
    );
    return maps.map((map) => ChatMessageEntity.fromJson(map)).toList();
  }

  /// Get messages for a session with pagination
  Future<List<ChatMessageEntity>> getBySessionIdPaginated({
    required String sessionId,
    int limit = 50,
    int offset = 0,
  }) async {
    final maps = await _database.query(
      TableNames.chatMessages,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sequence_number ASC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => ChatMessageEntity.fromJson(map)).toList();
  }

  /// Get the next sequence number for a session
  Future<int> getNextSequenceNumber(String sessionId) async {
    final result = await _database.rawQuery(
      'SELECT COALESCE(MAX(sequence_number), -1) + 1 as next_seq '
      'FROM ${TableNames.chatMessages} '
      'WHERE session_id = ?',
      [sessionId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Update a message
  Future<int> update(ChatMessageEntity message) async {
    return await _database.update(
      TableNames.chatMessages,
      message.toJson(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  /// Update message processing state
  Future<int> updateProcessingState({
    required String messageId,
    required bool isProcessing,
    String? error,
  }) async {
    final values = <String, dynamic>{
      'is_processing': isProcessing ? 1 : 0,
    };
    if (error != null) {
      values['error'] = error;
    }
    return await _database.update(
      TableNames.chatMessages,
      values,
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Delete a message
  Future<int> delete(String messageId) async {
    return await _database.delete(
      TableNames.chatMessages,
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Delete all messages for a session
  Future<int> deleteBySessionId(String sessionId) async {
    return await _database.delete(
      TableNames.chatMessages,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Count messages in a session
  Future<int> countBySessionId(String sessionId) async {
    final result = await _database.rawQuery(
      'SELECT COUNT(*) as count FROM ${TableNames.chatMessages} WHERE session_id = ?',
      [sessionId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get the last message for a session
  Future<ChatMessageEntity?> getLastMessage(String sessionId) async {
    final maps = await _database.query(
      TableNames.chatMessages,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sequence_number DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ChatMessageEntity.fromJson(maps.first);
  }
}
