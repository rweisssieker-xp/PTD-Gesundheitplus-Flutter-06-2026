import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/prevention/data/prevention_repository.dart';

void main() {
  test('stores vaccination records', () async {
    final db = AppDatabase.memory();
    final repo = PreventionRepository(db);
    await repo.addVaccination(
      vaccineName: 'Tetanus',
      targetDisease: 'Wundstarrkrampf',
      vaccinatedAt: DateTime(2026, 1, 10),
      nextDueAt: DateTime(2026, 6, 1),
    );
    final records = await repo.listVaccinations();
    expect(records.single.vaccineName, 'Tetanus');
    expect(records.single.targetDisease, 'Wundstarrkrampf');
    expect(records.single.boosterDue, isTrue);
    db.close();
  });

  test('stores and completes preventive care items', () async {
    final db = AppDatabase.memory();
    final repo = PreventionRepository(db);
    await repo.addPreventiveCare(
      title: 'Hautscreening',
      category: 'Screening',
      dueAt: DateTime(2026, 6, 1),
      intervalMonths: 24,
    );
    final created = await repo.listPreventiveCare();
    expect(created.single.isDue, isTrue);
    await repo.markPreventiveCareDone(created.single.id);
    final completed = await repo.listPreventiveCare();
    expect(completed.single.isDone, isTrue);
    db.close();
  });
}
