import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/medication.dart';

class MedicationRepository {
  MedicationRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> save(Medication medication) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO medications (
        id, name, dosage, frequency, active, schedule, start_date, end_date,
        prescribed_by, reason, reminder_enabled, reminder_times_json,
        supply_duration_days, refill_reminder_days, notes, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        dosage = excluded.dosage,
        frequency = excluded.frequency,
        active = excluded.active,
        schedule = excluded.schedule,
        start_date = excluded.start_date,
        end_date = excluded.end_date,
        prescribed_by = excluded.prescribed_by,
        reason = excluded.reason,
        reminder_enabled = excluded.reminder_enabled,
        reminder_times_json = excluded.reminder_times_json,
        supply_duration_days = excluded.supply_duration_days,
        refill_reminder_days = excluded.refill_reminder_days,
        notes = excluded.notes,
        updated_at = excluded.updated_at;
      ''',
      [
        medication.id,
        medication.name,
        medication.dosage,
        medication.frequency,
        medication.active ? 1 : 0,
        medication.schedule,
        medication.startDate?.toIso8601String(),
        medication.endDate?.toIso8601String(),
        medication.prescribedBy,
        medication.reason,
        medication.reminderEnabled ? 1 : 0,
        jsonEncode(medication.reminderTimes),
        medication.supplyDurationDays,
        medication.refillReminderDays,
        medication.notes,
        now,
        now,
      ],
    );
  }

  Future<void> delete(String id) async {
    _db.execute('DELETE FROM medications WHERE id = ?', [id]);
    _db.execute('DELETE FROM medication_logs WHERE medication_id = ?', [id]);
  }

  Future<List<Medication>> list({bool includeInactive = false}) async {
    final rows = _db.select('''
      SELECT id, name, dosage, frequency, schedule, start_date, end_date,
             prescribed_by, reason, reminder_enabled, reminder_times_json,
             supply_duration_days, refill_reminder_days, notes, active
      FROM medications
      ${includeInactive ? '' : 'WHERE active = 1'}
      ORDER BY active DESC, name COLLATE NOCASE
      ''');
    return rows.map(_medicationFromRow).toList();
  }

  Future<List<Medication>> listActive() async {
    return list();
  }

  Future<List<MedicationLog>> ensureDailyLogs(DateTime date) async {
    final dateKey = _dateKey(date);
    final medications = await listActive();
    final now = DateTime.now().toIso8601String();

    for (final medication in medications) {
      if (!medication.reminderEnabled) continue;
      for (final time in medication.reminderTimes.where(
        (time) => time.trim().isNotEmpty,
      )) {
        _db.execute(
          '''
          INSERT OR IGNORE INTO medication_logs (
            id, medication_id, medication_name, scheduled_time, dosage_taken,
            status, date, created_at, updated_at
          )
          VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?)
          ''',
          [
            _uuid.v4(),
            medication.id,
            medication.name,
            time,
            medication.dosage,
            dateKey,
            now,
            now,
          ],
        );
      }
    }
    return listLogs(date);
  }

  Future<List<MedicationLog>> listLogs(DateTime date) async {
    final rows = _db.select(
      '''
      SELECT id, medication_id, medication_name, scheduled_time, dosage_taken,
             status, date, taken_at, notes, confirmed_by_voice
      FROM medication_logs
      WHERE date = ?
      ORDER BY scheduled_time, medication_name COLLATE NOCASE
      ''',
      [_dateKey(date)],
    );
    return rows.map(_logFromRow).toList();
  }

  Future<void> updateLogStatus(
    String id,
    MedicationLogStatus status, {
    DateTime? takenAt,
    String? notes,
    bool confirmedByVoice = false,
  }) async {
    _db.execute(
      '''
      UPDATE medication_logs
      SET status = ?, taken_at = ?, notes = ?, confirmed_by_voice = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        status.name,
        takenAt?.toIso8601String(),
        notes,
        confirmedByVoice ? 1 : 0,
        DateTime.now().toIso8601String(),
        id,
      ],
    );
  }

  Medication _medicationFromRow(Map<String, Object?> row) {
    final reminderTimesRaw = row['reminder_times_json'] as String? ?? '[]';
    final reminderTimes = (jsonDecode(reminderTimesRaw) as List<dynamic>)
        .cast<String>();
    return Medication(
      id: row['id'] as String,
      name: row['name'] as String,
      dosage: row['dosage'] as String?,
      frequency: row['frequency'] as String?,
      schedule: row['schedule'] as String?,
      startDate: _parseDate(row['start_date'] as String?),
      endDate: _parseDate(row['end_date'] as String?),
      prescribedBy: row['prescribed_by'] as String?,
      reason: row['reason'] as String?,
      reminderEnabled: (row['reminder_enabled'] as int? ?? 1) == 1,
      reminderTimes: reminderTimes,
      supplyDurationDays: row['supply_duration_days'] as int?,
      refillReminderDays: row['refill_reminder_days'] as int?,
      notes: row['notes'] as String?,
      active: (row['active'] as int) == 1,
    );
  }

  MedicationLog _logFromRow(Map<String, Object?> row) {
    return MedicationLog(
      id: row['id'] as String,
      medicationId: row['medication_id'] as String,
      medicationName: row['medication_name'] as String,
      scheduledTime: row['scheduled_time'] as String,
      dosageTaken: row['dosage_taken'] as String?,
      status: MedicationLogStatus.fromStorage(row['status'] as String),
      date: DateTime.parse(row['date'] as String),
      takenAt: _parseDate(row['taken_at'] as String?),
      notes: row['notes'] as String?,
      confirmedByVoice: (row['confirmed_by_voice'] as int? ?? 0) == 1,
    );
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }
}
