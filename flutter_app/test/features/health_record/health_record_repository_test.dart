import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/health_record/data/health_record_repository.dart';
import 'package:gesundheitplus/src/features/medication/data/medication_repository.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication.dart';

void main() {
  test('stores and deletes anamnesis entries', () async {
    final db = AppDatabase.memory();
    final repo = HealthRecordRepository(db);
    await repo.addHistoryEntry(category: 'Vorerkrankung', title: 'Asthma');
    final created = await repo.listHistoryEntries();
    expect(created.single.title, 'Asthma');
    await repo.deleteHistoryEntry(created.single.id);
    expect(await repo.listHistoryEntries(), isEmpty);
    db.close();
  });

  test('stores and sorts treatment records', () async {
    final db = AppDatabase.memory();
    final repo = HealthRecordRepository(db);
    await repo.addTreatment(
      title: 'Kontrolle',
      treatedAt: DateTime(2026, 1, 1),
    );
    await repo.addTreatment(
      title: 'Operation',
      treatedAt: DateTime(2026, 6, 1),
    );
    final records = await repo.listTreatments();
    expect(records.first.title, 'Operation');
    db.close();
  });

  test('stores, updates, sorts, and deletes allergies', () async {
    final db = AppDatabase.memory();
    final repo = HealthRecordRepository(db);
    await repo.addAllergy(
      substance: 'Birke',
      category: 'Pollen',
      severity: 'Leicht',
      reaction: 'Niesen',
    );
    await repo.addAllergy(
      substance: 'Penicillin',
      category: 'Medikament',
      severity: 'Lebensbedrohlich',
      reaction: 'Atemnot',
    );

    final created = await repo.listAllergies();
    expect(created.first.substance, 'Penicillin');
    expect(created.first.category, 'Medikament');

    await repo.updateAllergy(
      id: created.first.id,
      substance: 'Penicillin',
      category: 'Medikament',
      severity: 'Schwer',
      reaction: 'Schwellung',
      notes: 'Notfallrelevant',
    );
    final updated = await repo.listAllergies();
    expect(updated.first.severity, 'Schwer');
    expect(updated.first.notes, 'Notfallrelevant');

    await repo.deleteAllergy(updated.first.id);
    final remaining = await repo.listAllergies();
    expect(remaining.single.substance, 'Birke');
    db.close();
  });

  test(
    'checks active medication against medication allergies locally',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final healthRepo = HealthRecordRepository(db);
      final medicationRepo = MedicationRepository(db);

      await healthRepo.addAllergy(
        substance: 'Penicillin',
        category: 'Medikament',
        severity: 'Lebensbedrohlich',
        reaction: 'Atemnot',
      );
      await medicationRepo.save(
        _medication(id: 'm1', name: 'Amoxicillin', active: true),
      );
      await medicationRepo.save(
        _medication(id: 'm2', name: 'Vitamin D', active: true),
      );

      final result = await healthRepo.checkMedicationAllergies();

      expect(result.activeMedicationCount, 2);
      expect(result.medicationAllergyCount, 1);
      expect(result.hasConflicts, isTrue);
      expect(result.overallRisk, 'kritisch');
      expect(result.conflicts.single.medicationName, 'Amoxicillin');
      expect(result.conflicts.single.severity, 'Kontraindiziert');
    },
  );

  test(
    'detects direct medication allergy matches and ignores inactive meds',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final healthRepo = HealthRecordRepository(db);
      final medicationRepo = MedicationRepository(db);

      await healthRepo.addAllergy(
        substance: 'Ibuprofen',
        category: 'Medikament',
        severity: 'Mittel',
      );
      await medicationRepo.save(
        _medication(id: 'm1', name: 'Ibuprofen 400', active: true),
      );
      await medicationRepo.save(
        _medication(id: 'm2', name: 'Ibuprofen alt', active: false),
      );

      final result = await healthRepo.checkMedicationAllergies();

      expect(result.conflicts, hasLength(1));
      expect(result.conflicts.single.severity, 'Schwerwiegend');
      expect(result.summary, contains('1 moegliche'));
    },
  );
}

Medication _medication({
  required String id,
  required String name,
  required bool active,
}) {
  return Medication(
    id: id,
    name: name,
    dosage: null,
    frequency: null,
    schedule: null,
    startDate: null,
    endDate: null,
    prescribedBy: null,
    reason: null,
    reminderEnabled: false,
    reminderTimes: const [],
    supplyDurationDays: null,
    refillReminderDays: null,
    notes: null,
    active: active,
  );
}
