import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/medication/data/medication_repository.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication.dart';

void main() {
  test('creates and lists medication', () async {
    final db = AppDatabase.memory();
    final repo = MedicationRepository(db);
    await repo.save(
      const Medication(id: 'm1', name: 'Ramipril', dosage: '5mg', active: true),
    );
    final meds = await repo.listActive();
    expect(meds.single.name, 'Ramipril');
    db.close();
  });
}
