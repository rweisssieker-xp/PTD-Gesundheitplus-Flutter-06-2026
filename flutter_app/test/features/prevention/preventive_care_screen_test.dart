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

  testWidgets('preventive care screen creates and completes local reminders', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await LocalProfileRepository(
      db,
    ).saveProfile(fullName: 'Patient', dateOfBirth: DateTime(1975, 1, 1));

    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: PreventiveCareScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Vorsorge'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Termin'));
    await tester.pumpAndSettle();

    expect(find.text('Vorsorge planen'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Titel *'),
      'Augencheck',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Kategorie'),
      'Screening',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Arzt / Praxis'),
      'Augenarztpraxis',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Faellig in Tagen'),
      '20',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Wiederholung in Monaten'),
      '12',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Augencheck'), findsOneWidget);
    expect(find.text('Aktive Reminder'), findsOneWidget);
    expect(find.text('In 30 Tagen'), findsOneWidget);

    var items = await PreventionRepository(db).listPreventiveCare();
    expect(items.single.title, 'Augencheck');
    expect(items.single.category, 'Screening');
    expect(items.single.doctorName, 'Augenarztpraxis');
    expect(items.single.intervalMonths, 12);
    expect(items.single.isDone, isFalse);

    await tester.tap(find.byTooltip('Als erledigt markieren'));
    await tester.pumpAndSettle();

    items = await PreventionRepository(db).listPreventiveCare();
    expect(items.single.isDone, isTrue);
    expect(find.text('Erledigt'), findsOneWidget);
  });
}
