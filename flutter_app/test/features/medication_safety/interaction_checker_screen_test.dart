import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/medication/data/medication_repository.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication.dart';
import 'package:gesundheitplus/src/features/medication_safety/data/medication_safety_repository.dart';
import 'package:gesundheitplus/src/features/medication_safety/presentation/interaction_checker_screen.dart';
import 'package:gesundheitplus/src/features/privacy/data/local_privacy_repository.dart';

void main() {
  testWidgets('interaction checker blocks local details without consent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: InteractionCheckerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kontextfreigabe fehlt'), findsOneWidget);
    expect(find.text('Noch keine Checks'), findsOneWidget);

    await tester.tap(find.text('Lokalen Check ausfuehren'));
    await tester.pumpAndSettle();

    expect(find.text('Risiko: niedrig'), findsOneWidget);
    expect(find.textContaining('Kontextfreigabe fehlt'), findsWidgets);

    final check = (await MedicationSafetyRepository(db).listChecks()).single;
    expect(check.consentUsed, isFalse);
    expect(check.summary, contains('Kontextfreigabe fehlt'));
  });

  testWidgets(
    'interaction checker stores high risk local result with consent',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.memory();
      addTearDown(db.close);
      await LocalPrivacyRepository(db).setAiContextAllowed(true);
      await MedicationRepository(db).save(_medication(id: 'm1', name: 'ASS'));
      await MedicationRepository(
        db,
      ).save(_medication(id: 'm2', name: 'Apixaban'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) => db)],
          child: const MaterialApp(home: InteractionCheckerScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kontextfreigabe aktiv'), findsOneWidget);
      expect(find.text('Noch keine Checks'), findsOneWidget);

      await tester.tap(find.text('Lokalen Check ausfuehren'));
      await tester.pumpAndSettle();

      expect(find.text('Risiko: hoch'), findsOneWidget);
      expect(find.textContaining('Blutungsrisiko'), findsOneWidget);

      final check = (await MedicationSafetyRepository(db).listChecks()).single;
      expect(check.consentUsed, isTrue);
      expect(check.riskLevel, 'hoch');
      expect(check.medicationNames, unorderedEquals(['ASS', 'Apixaban']));
    },
  );
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
