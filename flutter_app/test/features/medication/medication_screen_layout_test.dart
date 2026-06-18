import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/health_record/data/health_record_repository.dart';
import 'package:gesundheitplus/src/features/medication/data/medication_repository.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication.dart';
import 'package:gesundheitplus/src/features/medication/presentation/medication_screen.dart';

void main() {
  testWidgets('medication screen keeps original PWA page layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    await HealthRecordRepository(db).addAllergy(
      substance: 'Penicillin',
      category: 'Medikament',
      severity: 'Schwer',
    );
    await MedicationRepository(
      db,
    ).save(_medication(id: 'm1', name: 'Amoxicillin', active: true));
    await MedicationRepository(
      db,
    ).save(_medication(id: 'm2', name: 'Vitamin D alt', active: false));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: MedicationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medikation'), findsOneWidget);
    expect(find.text('Ihr Medikamentenplan'), findsOneWidget);
    expect(find.textContaining('Allergie'), findsWidgets);
    expect(find.text('Jetzt prüfen'), findsOneWidget);
    expect(
      find.text('1 Medikament(e) · 1 Medikamenten-Allergie(n)'),
      findsOneWidget,
    );
    expect(find.text('Sprachführung'), findsOneWidget);
    expect(find.text('Vorlesen'), findsOneWidget);
    expect(
      find.text('Aktive Medikamente', skipOffstage: false),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Sprache'),
      80,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Sprache'), findsOneWidget);
    expect(find.text('Hinzufügen'), findsOneWidget);
    expect(find.byIcon(Icons.add, skipOffstage: false), findsWidgets);
    expect(find.text('Amoxicillin', skipOffstage: false), findsOneWidget);
    expect(find.text('Vitamin D alt', skipOffstage: false), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('medication allergy interaction CTA opens local checker', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final router = GoRouter(
      initialLocation: '/medication',
      routes: [
        GoRoute(
          path: '/medication',
          builder: (context, state) => const MedicationScreen(),
        ),
        GoRoute(
          path: '/medication/interaction-checker',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Lokaler Wechselwirkungscheck')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jetzt prüfen'));
    await tester.pumpAndSettle();

    expect(find.text('Lokaler Wechselwirkungscheck'), findsOneWidget);
  });
}

Medication _medication({
  required String id,
  required String name,
  required bool active,
}) {
  return Medication(
    id: id,
    name: name,
    dosage: '1 Tablette',
    frequency: '1x täglich',
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
