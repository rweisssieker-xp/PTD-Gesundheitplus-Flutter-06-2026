import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication.dart';
import 'package:gesundheitplus/src/features/medication/data/medication_repository.dart';
import 'package:gesundheitplus/src/features/medication_safety/data/medication_safety_repository.dart';

void main() {
  test('stores local interaction guidance', () async {
    final db = AppDatabase.memory();
    final repo = MedicationSafetyRepository(db);
    await repo.addGuidance(
      title: 'ASS + Antikoagulanzien',
      severity: 'hoch',
      description: 'Blutungsrisiko pruefen',
    );
    final guidance = await repo.listGuidance();
    expect(guidance.single.severity, 'hoch');
    db.close();
  });

  test('blocks check details when consent is missing', () async {
    final db = AppDatabase.memory();
    final repo = MedicationSafetyRepository(db);
    final check = await repo.runLocalCheck(consentAllowed: false);
    expect(check.consentUsed, isFalse);
    expect(check.summary, contains('Kontextfreigabe fehlt'));
    db.close();
  });

  test('detects local high risk medication rule with consent', () async {
    final db = AppDatabase.memory();
    final medicationRepo = MedicationRepository(db);
    await medicationRepo.save(_medication(id: 'm1', name: 'ASS'));
    await medicationRepo.save(_medication(id: 'm2', name: 'Apixaban'));
    final check = await MedicationSafetyRepository(
      db,
    ).runLocalCheck(consentAllowed: true);
    expect(check.riskLevel, 'hoch');
    expect(check.summary, contains('Blutungsrisiko'));
    db.close();
  });
}

Medication _medication({required String id, required String name}) {
  return Medication(
    id: id,
    name: name,
    dosage: '100mg',
    frequency: 'taeglich',
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
    active: true,
  );
}
