import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/onboarding/data/local_profile_repository.dart';
import 'package:gesundheitplus/src/features/prevention/data/prevention_repository.dart';
import 'package:gesundheitplus/src/features/prevention/presentation/preventive_care_screen.dart';

void main() {
  testWidgets('preventive care screen shows PWA reminder stats locally', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await LocalProfileRepository(
      db,
    ).saveProfile(fullName: 'Patient', dateOfBirth: DateTime(1980, 1, 1));
    final repo = PreventionRepository(db);
    await repo.addPreventiveCare(
      title: 'Hautkrebsvorsorge',
      category: 'Screening',
      dueAt: DateTime.now().add(const Duration(days: 14)),
      intervalMonths: 24,
      doctorName: 'Dermatologie',
    );

    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: PreventiveCareScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vorsorge & Praevention'), findsOneWidget);
    expect(
      find.text('Personalisierte Gesundheitsempfehlungen'),
      findsOneWidget,
    );
    expect(find.text('Aktive Reminder'), findsOneWidget);
    expect(find.text('In 30 Tagen'), findsOneWidget);
    expect(find.text('Gesamt'), findsOneWidget);
    expect(
      find.textContaining(
        'Erinnerungen werden lokal auf diesem Geraet geplant',
      ),
      findsOneWidget,
    );
    expect(find.text('Lokale Vorsorge-Empfehlungen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Hautkrebsvorsorge'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Hautkrebsvorsorge'), findsWidgets);
  });
}
