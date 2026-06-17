import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/medication/data/medication_repository.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication.dart';

void main() {
  test('creates and lists medication', () async {
    final db = AppDatabase.memory();
    final repo = MedicationRepository(db);
    await repo.save(
      const Medication(
        id: 'm1',
        name: 'Ramipril',
        dosage: '5mg',
        frequency: '1x taeglich',
        schedule: 'morgens',
        startDate: null,
        endDate: null,
        prescribedBy: 'Hausarzt',
        reason: 'Blutdruck',
        reminderEnabled: true,
        reminderTimes: ['08:00'],
        refillReminderDays: 7,
        notes: 'Mit Wasser',
        active: true,
      ),
    );
    final meds = await repo.listActive();
    expect(meds.single.name, 'Ramipril');
    expect(meds.single.reminderTimes, ['08:00']);
    db.close();
  });

  test('creates daily medication logs from reminder times', () async {
    final db = AppDatabase.memory();
    final repo = MedicationRepository(db);
    await repo.save(
      const Medication(
        id: 'm1',
        name: 'Ramipril',
        dosage: '5mg',
        frequency: '1x taeglich',
        schedule: 'morgens',
        startDate: null,
        endDate: null,
        prescribedBy: null,
        reason: null,
        reminderEnabled: true,
        reminderTimes: ['08:00', '20:00'],
        refillReminderDays: 7,
        notes: null,
        active: true,
      ),
    );

    final logs = await repo.ensureDailyLogs(DateTime(2026, 6, 17));
    expect(logs, hasLength(2));
    expect(logs.first.status, MedicationLogStatus.pending);

    await repo.updateLogStatus(
      logs.first.id,
      MedicationLogStatus.taken,
      takenAt: DateTime(2026, 6, 17, 8, 5),
    );
    final updated = await repo.listLogs(DateTime(2026, 6, 17));
    expect(updated.first.status, MedicationLogStatus.taken);
    expect(updated.first.takenAt, DateTime(2026, 6, 17, 8, 5));

    db.close();
  });
}
