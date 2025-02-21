// lib/services/local_database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'learning_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Topics table
        await db.execute('''
          CREATE TABLE topics (
            id TEXT PRIMARY KEY,
            subject TEXT,
            name TEXT,
            status TEXT,
            stage TEXT,
            created_at TEXT,
            next_review TEXT,
            sync_status TEXT,
            last_modified TEXT
          )
        ''');

        // Reviews table
        await db.execute('''
          CREATE TABLE reviews (
            id TEXT PRIMARY KEY,
            topic_id TEXT,
            date TEXT,
            difficulty TEXT,
            interval INTEGER,
            sync_status TEXT,
            FOREIGN KEY (topic_id) REFERENCES topics (id)
          )
        ''');

        // Tasks table
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT,
            is_completed INTEGER,
            created_at TEXT,
            due_date TEXT,
            energy_level TEXT,
            duration TEXT,
            sync_status TEXT,
            last_modified TEXT
          )
        ''');

        // Calendar events table
        await db.execute('''
          CREATE TABLE events (
            id TEXT PRIMARY KEY,
            title TEXT,
            start_time TEXT,
            end_time TEXT,
            type TEXT,
            description TEXT,
            sync_status TEXT,
            last_modified TEXT
          )
        ''');
      },
    );
  }
}