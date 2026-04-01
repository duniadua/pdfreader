import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database name for chat history
const String _databaseName = 'chat_history.db';

/// Current database version
const int _databaseVersion = 1;

/// Table names
class TableNames {
  static const String chatSessions = 'chat_sessions';
  static const String chatMessages = 'chat_messages';
}

/// SQLite database helper for chat history persistence.
/// Uses singleton pattern to ensure only one database instance exists.
class ChatDatabase {
  /// Singleton instance
  static ChatDatabase? _instance;

  /// Database instance
  Database? _database;

  /// Private constructor
  ChatDatabase._();

  /// Get singleton instance
  static ChatDatabase get instance {
    _instance ??= ChatDatabase._();
    return _instance!;
  }

  /// Get the database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    // Get the database path
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    // Open the database, creating it if it doesn't exist
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
    );
  }

  /// Create database schema (called on first creation)
  Future<void> _onCreate(Database db, int version) async {
    // Create chat_sessions table
    await db.execute('''
      CREATE TABLE ${TableNames.chatSessions} (
        id TEXT PRIMARY KEY,
        pdf_id TEXT NOT NULL,
        pdf_title TEXT NOT NULL,
        pdf_file_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        message_count INTEGER NOT NULL DEFAULT 0,
        last_message_at INTEGER,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for chat_sessions
    await db.execute('''
      CREATE INDEX idx_sessions_pdf_id ON ${TableNames.chatSessions}(pdf_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_sessions_last_message ON ${TableNames.chatSessions}(last_message_at DESC)
    ''');

    // Create chat_messages table
    await db.execute('''
      CREATE TABLE ${TableNames.chatMessages} (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        content TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        is_processing INTEGER NOT NULL DEFAULT 0,
        error TEXT,
        sequence_number INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES ${TableNames.chatSessions}(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for chat_messages
    await db.execute('''
      CREATE INDEX idx_messages_session_id ON ${TableNames.chatMessages}(session_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_messages_timestamp ON ${TableNames.chatMessages}(timestamp)
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_messages_sequence ON ${TableNames.chatMessages}(session_id, sequence_number)
    ''');
  }

  /// Handle database upgrades (for future migrations)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations will be handled here
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE ...');
    // }
  }

  /// Handle database downgrades
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    // Handle schema downgrades if necessary
    // For now, we'll recreate the database
    await db.close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    // Use the fully qualified deleteDatabase function from sqflite
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Close the database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete the database (useful for testing or reset)
  Future<void> deleteDatabase() async {
    await close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
  }
}
