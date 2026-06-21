import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/vitals.dart';

class VitalsRepository {
  VitalsRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> addBloodPressure({
    required int systolic,
    required int diastolic,
    int? pulse,
    String context = 'Ruhe',
    DateTime? measuredAt,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO blood_pressure_logs (id, systolic, diastolic, pulse, context, measured_at, notes, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        systolic,
        diastolic,
        pulse,
        context,
        (measuredAt ?? DateTime.now()).toIso8601String(),
        notes,
        now,
        now,
      ],
    );
  }

  Future<List<BloodPressureLog>> listBloodPressure() async {
    final rows = _db.select(
      'SELECT id, systolic, diastolic, pulse, context, measured_at, notes FROM blood_pressure_logs ORDER BY measured_at DESC',
    );
    return rows
        .map(
          (row) => BloodPressureLog(
            id: row['id'] as String,
            systolic: row['systolic'] as int,
            diastolic: row['diastolic'] as int,
            pulse: row['pulse'] as int?,
            context: row['context'] as String,
            measuredAt: DateTime.parse(row['measured_at'] as String),
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<void> deleteBloodPressure(String id) async {
    _db.execute('DELETE FROM blood_pressure_logs WHERE id = ?', [id]);
  }

  Future<void> addWeight({
    required double weightKg,
    double? heightCm,
    DateTime? measuredAt,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO weight_logs (id, weight_kg, height_cm, measured_at, notes, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        weightKg,
        heightCm,
        (measuredAt ?? DateTime.now()).toIso8601String(),
        notes,
        now,
        now,
      ],
    );
  }

  Future<List<WeightLog>> listWeight() async {
    final rows = _db.select(
      'SELECT id, weight_kg, height_cm, measured_at, notes FROM weight_logs ORDER BY measured_at DESC',
    );
    return rows
        .map(
          (row) => WeightLog(
            id: row['id'] as String,
            weightKg: row['weight_kg'] as double,
            heightCm: row['height_cm'] as double?,
            measuredAt: DateTime.parse(row['measured_at'] as String),
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<void> deleteWeight(String id) async {
    _db.execute('DELETE FROM weight_logs WHERE id = ?', [id]);
  }
}
