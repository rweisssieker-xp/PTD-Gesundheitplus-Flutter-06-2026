import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/health_record.dart';

class HealthRecordRepository {
  HealthRecordRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> addHistoryEntry({
    required String category,
    required String title,
    String? details,
    DateTime? occurredAt,
    bool active = true,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO medical_history_entries (
        id, category, title, details, occurred_at, active, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        category,
        title,
        details,
        occurredAt?.toIso8601String(),
        active ? 1 : 0,
        now,
        now,
      ],
    );
  }

  Future<List<MedicalHistoryEntry>> listHistoryEntries() async {
    final rows = _db.select('''
      SELECT id, category, title, details, occurred_at, active
      FROM medical_history_entries
      ORDER BY category ASC, title ASC
      ''');
    return rows
        .map(
          (row) => MedicalHistoryEntry(
            id: row['id'] as String,
            category: row['category'] as String,
            title: row['title'] as String,
            details: row['details'] as String?,
            occurredAt: _date(row['occurred_at']),
            active: row['active'] == 1,
          ),
        )
        .toList();
  }

  Future<void> deleteHistoryEntry(String id) async {
    _db.execute('DELETE FROM medical_history_entries WHERE id = ?', [id]);
  }

  Future<void> addTreatment({
    required String title,
    String? provider,
    String? specialty,
    DateTime? treatedAt,
    String? outcome,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO treatment_records (
        id, title, provider, specialty, treated_at, outcome, notes, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        title,
        provider,
        specialty,
        (treatedAt ?? DateTime.now()).toIso8601String(),
        outcome,
        notes,
        now,
        now,
      ],
    );
  }

  Future<List<TreatmentRecord>> listTreatments() async {
    final rows = _db.select('''
      SELECT id, title, provider, specialty, treated_at, outcome, notes
      FROM treatment_records
      ORDER BY treated_at DESC
      ''');
    return rows
        .map(
          (row) => TreatmentRecord(
            id: row['id'] as String,
            title: row['title'] as String,
            provider: row['provider'] as String?,
            specialty: row['specialty'] as String?,
            treatedAt: DateTime.parse(row['treated_at'] as String),
            outcome: row['outcome'] as String?,
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<void> deleteTreatment(String id) async {
    _db.execute('DELETE FROM treatment_records WHERE id = ?', [id]);
  }

  DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}
