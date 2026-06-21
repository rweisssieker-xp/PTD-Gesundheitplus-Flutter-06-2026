import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/medication/data/medication_repository.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication.dart';
import 'package:gesundheitplus/src/features/medication_safety/data/medication_safety_repository.dart';
import 'package:gesundheitplus/src/features/medication_safety/presentation/medication_interactions_screen.dart';

void main() {
  testWidgets(
    'medication interactions screen shows local PWA safety overview',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.memory();
      addTearDown(db.close);
      final medicationRepo = MedicationRepository(db);
      await medicationRepo.save(_medication(id: 'm1', name: 'ASS'));
      await medicationRepo.save(_medication(id: 'm2', name: 'Apixaban'));
      await MedicationSafetyRepository(db).addGuidance(
        title: 'ASS + Antikoagulanzien',
        severity: 'hoch',
        description: 'Blutungsrisiko pruefen',
        action: 'Aerztlich klaeren',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
          child: const MaterialApp(home: MedicationInteractionsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Medikations-Wechselwirkungen'), findsOneWidget);
      expect(
        find.textContaining('Lokale Prüfung Ihrer aktiven Medikamente'),
        findsOneWidget,
      );
      expect(find.text('Sicherheit zuerst'), findsOneWidget);
      expect(find.text('Was wird geprüft?'), findsOneWidget);
      expect(find.text('Lokaler Checker bereit'), findsOneWidget);
      expect(find.text('2 aktiv'), findsOneWidget);
      expect(find.text('Lokalen Check öffnen'), findsOneWidget);
      expect(find.text('Ihre aktiven Medikamente (2)'), findsOneWidget);
      expect(find.text('ASS'), findsOneWidget);
      expect(find.text('Apixaban'), findsOneWidget);
      expect(find.text('Lokale Interaktionshinweise'), findsOneWidget);
      expect(find.text('ASS + Antikoagulanzien'), findsOneWidget);
      expect(find.textContaining('Blutungsrisiko pruefen'), findsOneWidget);
    },
  );

  testWidgets('medication interactions screen shows minimum medication hint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: MedicationInteractionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hinweis'), findsWidgets);
    expect(find.textContaining('0 aktive Medikamente'), findsOneWidget);
    expect(find.text('Medikamente verwalten'), findsOneWidget);
    expect(find.text('Mehr aktive Medikamente nötig'), findsOneWidget);
    expect(find.text('0 aktiv'), findsOneWidget);
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
