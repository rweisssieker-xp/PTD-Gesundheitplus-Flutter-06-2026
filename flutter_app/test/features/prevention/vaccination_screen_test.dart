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
    _seedHealthPass(db);

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
  });
}

void _seedHealthPass(AppDatabase db) {
  db.execute('''
    INSERT INTO health_documents (
      id, title, category, local_path, encrypted, captured_at, created_at, updated_at
    )
    VALUES (
      'pass-1',
      'Implantatpass Knie',
      'Implantatpass',
      '/tmp/implantatpass.pdf',
      1,
      '2026-06-01T00:00:00.000',
      'now',
      'now'
    )
    ''');
}
