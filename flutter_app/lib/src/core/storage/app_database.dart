import 'package:sqlite3/sqlite3.dart';

import 'tables.dart';

class AppDatabase {
  AppDatabase._(this._db, {String? encryptionKey}) {
    if (encryptionKey != null) {
      _db.execute("PRAGMA key = '${_escapePragmaString(encryptionKey)}';");
      _db.select('SELECT count(*) FROM sqlite_master');
    }
    _migrate();
  }

  factory AppDatabase.memory() => AppDatabase._(sqlite3.openInMemory());

  factory AppDatabase.local(String path, {required String encryptionKey}) =>
      AppDatabase._(sqlite3.open(path), encryptionKey: encryptionKey);

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
        schedule TEXT,
        start_date TEXT,
        end_date TEXT,
        prescribed_by TEXT,
        reason TEXT,
        reminder_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_times_json TEXT NOT NULL DEFAULT '[]',
        supply_duration_days INTEGER,
        refill_reminder_days INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _ensureColumn('medications', 'schedule', 'TEXT');
    _ensureColumn('medications', 'end_date', 'TEXT');
    _ensureColumn('medications', 'prescribed_by', 'TEXT');
    _ensureColumn('medications', 'reason', 'TEXT');
    _ensureColumn(
      'medications',
      'reminder_enabled',
      'INTEGER NOT NULL DEFAULT 1',
    );
    _ensureColumn(
      'medications',
      'reminder_times_json',
      "TEXT NOT NULL DEFAULT '[]'",
    );
    _ensureColumn('medications', 'notes', 'TEXT');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS medication_logs (
        id TEXT PRIMARY KEY,
        medication_id TEXT NOT NULL,
        medication_name TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        dosage_taken TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        date TEXT NOT NULL,
        taken_at TEXT,
        notes TEXT,
        confirmed_by_voice INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_medication_logs_unique_slot
      ON medication_logs (medication_id, date, scheduled_time);
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS medication_interaction_guidance (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        severity TEXT NOT NULL,
        description TEXT NOT NULL,
        action TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS medication_interaction_checks (
        id TEXT PRIMARY KEY,
        medication_names TEXT NOT NULL,
        risk_level TEXT NOT NULL,
        summary TEXT NOT NULL,
        consent_used INTEGER NOT NULL DEFAULT 0,
        checked_at TEXT NOT NULL,
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
        doctor_name TEXT,
        specialty TEXT,
        date TEXT,
        time TEXT,
        reason TEXT,
        reminder_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_hours_before INTEGER NOT NULL DEFAULT 24,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'Geplant',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _ensureColumn('appointments', 'doctor_name', 'TEXT');
    _ensureColumn('appointments', 'specialty', 'TEXT');
    _ensureColumn('appointments', 'date', 'TEXT');
    _ensureColumn('appointments', 'time', 'TEXT');
    _ensureColumn('appointments', 'reason', 'TEXT');
    _ensureColumn(
      'appointments',
      'reminder_enabled',
      'INTEGER NOT NULL DEFAULT 1',
    );
    _ensureColumn(
      'appointments',
      'reminder_hours_before',
      'INTEGER NOT NULL DEFAULT 24',
    );
    _ensureColumn('appointments', 'notes', 'TEXT');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS healthcare_professionals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        notes TEXT,
        treating_since TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS medical_history_entries (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        details TEXT,
        occurred_at TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS treatment_records (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        provider TEXT,
        specialty TEXT,
        treated_at TEXT NOT NULL,
        outcome TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS allergies (
        id TEXT PRIMARY KEY,
        substance TEXT NOT NULL,
        category TEXT,
        reaction TEXT,
        severity TEXT,
        diagnosed_at TEXT,
        diagnosed_by TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _ensureColumn('allergies', 'category', 'TEXT');
    _ensureColumn('allergies', 'diagnosed_at', 'TEXT');
    _ensureColumn('allergies', 'diagnosed_by', 'TEXT');
    _ensureColumn('allergies', 'notes', 'TEXT');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS blood_pressure_logs (
        id TEXT PRIMARY KEY,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        pulse INTEGER,
        measured_at TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS weight_logs (
        id TEXT PRIMARY KEY,
        weight_kg REAL NOT NULL,
        height_cm REAL,
        measured_at TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS vaccinations (
        id TEXT PRIMARY KEY,
        vaccine_name TEXT NOT NULL,
        target_disease TEXT,
        vaccinated_at TEXT NOT NULL,
        next_due_at TEXT,
        batch_number TEXT,
        doctor_name TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS preventive_care_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        due_at TEXT NOT NULL,
        interval_months INTEGER,
        status TEXT NOT NULL DEFAULT 'offen',
        doctor_name TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS health_documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        local_path TEXT NOT NULL,
        mime_type TEXT,
        captured_at TEXT NOT NULL,
        notes TEXT,
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
    _db.execute('''
      CREATE TABLE IF NOT EXISTS app_preferences (
        id TEXT PRIMARY KEY,
        language_code TEXT NOT NULL DEFAULT 'de',
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS ai_coach_messages (
        id TEXT PRIMARY KEY,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        consent_used INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS communication_preferences (
        id TEXT PRIMARY KEY,
        channel TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 0,
        display_name TEXT,
        target_value TEXT,
        notes TEXT,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS family_members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        relationship TEXT,
        phone TEXT,
        role TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS family_check_ins (
        id TEXT PRIMARY KEY,
        member_id TEXT,
        member_name TEXT NOT NULL,
        status TEXT NOT NULL,
        note TEXT,
        location_text TEXT,
        checked_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    _ensureColumn('family_check_ins', 'location_text', 'TEXT');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS dementia_logs (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        value TEXT NOT NULL,
        note TEXT,
        logged_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
  }

  void _ensureColumn(String table, String column, String definition) {
    final columns = _db.select('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      _db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  static String _escapePragmaString(String value) =>
      value.replaceAll("'", "''");
}
