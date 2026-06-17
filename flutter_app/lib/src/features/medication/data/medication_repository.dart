import '../../../core/storage/app_database.dart';
import '../domain/medication.dart';

class MedicationRepository {
  MedicationRepository(this._db);

  final AppDatabase _db;

  Future<void> save(Medication medication) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO medications (id, name, dosage, active, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        dosage = excluded.dosage,
        active = excluded.active,
        updated_at = excluded.updated_at;
      ''',
      [
        medication.id,
        medication.name,
        medication.dosage,
        medication.active ? 1 : 0,
        now,
        now,
      ],
    );
  }

  Future<List<Medication>> listActive() async {
    final rows = _db.select(
      'SELECT id, name, dosage, active FROM medications WHERE active = 1 ORDER BY name COLLATE NOCASE',
    );
    return rows
        .map(
          (row) => Medication(
            id: row['id'] as String,
            name: row['name'] as String,
            dosage: row['dosage'] as String?,
            active: (row['active'] as int) == 1,
          ),
        )
        .toList();
  }
}
