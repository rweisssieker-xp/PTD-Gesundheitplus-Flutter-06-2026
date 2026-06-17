import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/prevention.dart';

class PreventionRepository {
  PreventionRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> addVaccination({
    required String vaccineName,
    String? targetDisease,
    DateTime? vaccinatedAt,
    DateTime? nextDueAt,
    String? batchNumber,
    String? doctorName,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO vaccinations (
        id, vaccine_name, target_disease, vaccinated_at, next_due_at,
        batch_number, doctor_name, notes, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        vaccineName,
        targetDisease,
        (vaccinatedAt ?? DateTime.now()).toIso8601String(),
        nextDueAt?.toIso8601String(),
        batchNumber,
        doctorName,
        notes,
        now,
        now,
      ],
    );
  }

  Future<List<VaccinationRecord>> listVaccinations() async {
    final rows = _db.select('''
      SELECT id, vaccine_name, target_disease, vaccinated_at, next_due_at,
             batch_number, doctor_name, notes
      FROM vaccinations
      ORDER BY vaccinated_at DESC
      ''');
    return rows
        .map(
          (row) => VaccinationRecord(
            id: row['id'] as String,
            vaccineName: row['vaccine_name'] as String,
            targetDisease: row['target_disease'] as String?,
            vaccinatedAt: DateTime.parse(row['vaccinated_at'] as String),
            nextDueAt: _date(row['next_due_at']),
            batchNumber: row['batch_number'] as String?,
            doctorName: row['doctor_name'] as String?,
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<PreventiveCareItem> addPreventiveCare({
    required String title,
    required String category,
    required DateTime dueAt,
    int? intervalMonths,
    String? doctorName,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();
    _db.execute(
      '''
      INSERT INTO preventive_care_items (
        id, title, category, due_at, interval_months, status,
        doctor_name, notes, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, 'offen', ?, ?, ?, ?)
      ''',
      [
        id,
        title,
        category,
        dueAt.toIso8601String(),
        intervalMonths,
        doctorName,
        notes,
        now,
        now,
      ],
    );
    return PreventiveCareItem(
      id: id,
      title: title,
      category: category,
      dueAt: dueAt,
      intervalMonths: intervalMonths,
      status: 'offen',
      doctorName: doctorName,
      notes: notes,
    );
  }

  Future<List<PreventiveCareItem>> listPreventiveCare() async {
    final rows = _db.select('''
      SELECT id, title, category, due_at, interval_months, status, doctor_name, notes
      FROM preventive_care_items
      ORDER BY due_at ASC
      ''');
    return rows
        .map(
          (row) => PreventiveCareItem(
            id: row['id'] as String,
            title: row['title'] as String,
            category: row['category'] as String,
            dueAt: DateTime.parse(row['due_at'] as String),
            intervalMonths: row['interval_months'] as int?,
            status: row['status'] as String,
            doctorName: row['doctor_name'] as String?,
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<void> markPreventiveCareDone(String id) async {
    _db.execute(
      '''
      UPDATE preventive_care_items
      SET status = 'erledigt', updated_at = ?
      WHERE id = ?
      ''',
      [DateTime.now().toIso8601String(), id],
    );
  }

  DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}
