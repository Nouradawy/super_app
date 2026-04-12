import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton access to the app SQLite database.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'whatsunity.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE messages (
  id TEXT PRIMARY KEY NOT NULL,
  channel_id INTEGER NOT NULL,
  author_id TEXT NOT NULL,
  content TEXT,
  uri TEXT,
  type TEXT,
  created_at TEXT NOT NULL,
  created_at_ms INTEGER NOT NULL,
  metadata TEXT NOT NULL,
  sent_at TEXT,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 1,
  payload_json TEXT NOT NULL
);
''');
    await db.execute(
      'CREATE INDEX idx_messages_channel_time ON messages (channel_id, created_at_ms);',
    );
  }

  /// Call from tests or account reset if needed.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
