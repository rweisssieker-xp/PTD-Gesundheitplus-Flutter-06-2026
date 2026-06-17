import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/vitals/data/vitals_repository.dart';

void main() {
  test('stores blood pressure logs', () async {
    final db = AppDatabase.memory();
    final repo = VitalsRepository(db);
    await repo.addBloodPressure(
      systolic: 120,
      diastolic: 80,
      pulse: 70,
      measuredAt: DateTime(2026, 6, 17, 8),
    );
    final logs = await repo.listBloodPressure();
    expect(logs.single.systolic, 120);
    expect(logs.single.diastolic, 80);
    db.close();
  });

  test('stores weight logs and calculates BMI', () async {
    final db = AppDatabase.memory();
    final repo = VitalsRepository(db);
    await repo.addWeight(
      weightKg: 80,
      heightCm: 180,
      measuredAt: DateTime(2026, 6, 17, 8),
    );
    final logs = await repo.listWeight();
    expect(logs.single.weightKg, 80);
    expect(logs.single.bmi!.toStringAsFixed(1), '24.7');
    db.close();
  });
}
