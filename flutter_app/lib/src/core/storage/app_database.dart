import 'package:sqlite3/sqlite3.dart';

import 'tables.dart';

class AppDatabase {
  AppDatabase._(this._db) {
    _migrate();
  }

  factory AppDatabase.memory() => AppDatabase._(sqlite3.openInMemory());

  factory AppDatabase.local(String path) => AppDatabase._(sqlite3.open(path));

  final Database _db;

  List<AppTable> get allTables => AppTables.all;

  void execute(String sql, [List<Object?> parameters = const []]) {
    _db.execute(sql, parameters);
  }

  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    return _db.select(sql, parameters);
  }

  void close() {
    _db.dispose();
  }

  void _migrate() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS local_profiles (
        id TEXT PRIMARY KEY,
        full_name TEXT,
        date_of_birth TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS medications (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        dosage TEXT,
        frequency TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        start_date TEXT,
        supply_duration_days INTEGER,
        refill_reminder_days INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS appointments (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        starts_at TEXT NOT NULL,
        location TEXT,
        professional_id TEXT,
        status TEXT NOT NULL DEFAULT 'Geplant',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS allergies (
        id TEXT PRIMARY KEY,
        substance TEXT NOT NULL,
        reaction TEXT,
        severity TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS emergency_contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        relationship TEXT,
        phone TEXT,
        email TEXT,
        messenger TEXT,
        verified INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        category TEXT NOT NULL,
        read INTEGER NOT NULL DEFAULT 0,
        scheduled_at TEXT,
        created_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS consent_settings (
        id TEXT PRIMARY KEY,
        ai_context_allowed INTEGER NOT NULL DEFAULT 0,
        ai_consent_granted_at TEXT,
        updated_at TEXT NOT NULL
      );
    ''');
  }
}
