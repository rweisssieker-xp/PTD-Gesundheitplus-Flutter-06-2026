import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/onboarding/data/local_profile_repository.dart';
import 'package:gesundheitplus/src/features/prevention/data/prevention_repository.dart';
import 'package:gesundheitplus/src/features/prevention/presentation/vaccination_screen.dart';

void main() {
  testWidgets('vaccination screen mirrors local-first pass dashboard', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await LocalProfileRepository(
      db,
    ).saveProfile(fullName: 'Patient', dateOfBirth: DateTime(1960, 1, 1));
    final repo = PreventionRepository(db);
    await repo.addVaccination(
      vaccineName: 'Tetanus',
      targetDisease: 'Wundstarrkrampf',
      vaccinatedAt: DateTime(2014, 1, 10),
      nextDueAt: DateTime(2026, 6, 1),
      batchNumber: 'ABC123',
      doctorName: 'Hausarztpraxis',
    );
    await repo.addHealthPass(
      passType: 'Implantatpass',
      title: 'Implantatpass Knie',
      implantedAt: DateTime(2026, 6, 1),
      manufacturer: 'MediCorp',
      model: 'K-42',
      material: 'Titan',
      serialNumber: 'SN123',
    );

    tester.view.physicalSize = const Size(430, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: VaccinationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Impfpass & Gesundheitspaesse'), findsOneWidget);
    expect(
      find.text('Ihre Impfungen und wichtigen Gesundheitsdokumente'),
      findsOneWidget,
    );
    expect(find.text('1 Impfungen lokal gespeichert'), findsOneWidget);
    expect(find.text('KI-Impfempfehlungen'), findsOneWidget);
    expect(find.text('Anstehende Auffrischungen'), findsOneWidget);
    expect(find.text('Tetanus'), findsWidgets);
    expect(find.text('Charge ABC123'), findsOneWidget);
    expect(find.text('Impfungen (1)'), findsOneWidget);
    expect(find.text('Paesse (1)'), findsOneWidget);

    await tester.tap(find.text('Paesse (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Implantatpass Knie'), findsOneWidget);
    expect(find.textContaining('Implantatpass'), findsWidgets);
    expect(find.textContaining('MediCorp'), findsOneWidget);
    expect(find.textContaining('SN123'), findsOneWidget);
  });

  testWidgets('vaccination screen creates local vaccination records', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await LocalProfileRepository(
      db,
    ).saveProfile(fullName: 'Patient', dateOfBirth: DateTime(1990, 1, 1));

    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: VaccinationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 Impfungen lokal gespeichert'), findsOneWidget);
    expect(find.text('Noch keine Impfungen'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Impfung'));
    await tester.pumpAndSettle();

    expect(find.text('Impfung erfassen'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Impfstoff *'),
      'Influenza',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Schutz gegen'),
      'Grippe',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Arzt / Praxis'),
      'Hausarztpraxis',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Auffrischung in Monaten'),
      '12',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('1 Impfungen lokal gespeichert'), findsOneWidget);
    expect(find.text('Influenza'), findsOneWidget);
    expect(find.textContaining('Grippe'), findsOneWidget);
    expect(find.textContaining('Hausarztpraxis'), findsOneWidget);

    final records = await PreventionRepository(db).listVaccinations();
    expect(records.single.vaccineName, 'Influenza');
    expect(records.single.targetDisease, 'Grippe');
    expect(records.single.doctorName, 'Hausarztpraxis');
    expect(records.single.nextDueAt, isNotNull);
  });

  testWidgets('vaccination screen manages local health passes', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await LocalProfileRepository(
      db,
    ).saveProfile(fullName: 'Patient', dateOfBirth: DateTime(1990, 1, 1));

    tester.view.physicalSize = const Size(430, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: VaccinationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paesse (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Gesundheitspaesse'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Pass'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Bezeichnung *'),
      'Herzschrittmacherpass',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Implantationsdatum'),
      '2025-05-04',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Hersteller'),
      'CardioTech',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Modell'), 'CT-7');
    await tester.enterText(find.widgetWithText(TextField, 'Material'), 'Titan');
    await tester.enterText(
      find.widgetWithText(TextField, 'Seriennummer'),
      'SN-999',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Paesse (1)'), findsOneWidget);
    expect(find.text('Herzschrittmacherpass'), findsOneWidget);
    expect(find.textContaining('CardioTech'), findsOneWidget);
    expect(find.textContaining('SN-999'), findsOneWidget);

    await tester.tap(find.byTooltip('Bearbeiten'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Bezeichnung *'),
      'Herzschrittmacherpass aktualisiert',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Modell'), 'CT-8');
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Herzschrittmacherpass aktualisiert'), findsOneWidget);
    expect(find.textContaining('CT-8'), findsOneWidget);

    await tester.tap(find.byTooltip('Loeschen'));
    await tester.pumpAndSettle();

    expect(find.text('Paesse (0)'), findsOneWidget);
    expect(find.text('Noch keine Gesundheitspaesse'), findsOneWidget);
    expect(await PreventionRepository(db).listHealthPasses(), isEmpty);
  });
}
