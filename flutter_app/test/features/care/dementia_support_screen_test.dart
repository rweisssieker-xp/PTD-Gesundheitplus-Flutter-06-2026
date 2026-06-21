import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/care/data/care_repository.dart';
import 'package:gesundheitplus/src/features/care/presentation/dementia_support_screen.dart';

void main() {
  testWidgets('dementia support screen mirrors local PWA daily dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = CareRepository(db);
    final now = DateTime.now();
    await repo.addDementiaLog(
      type: 'Trinken',
      value: '250 ml Wasser',
      note: 'Getraenk: Wasser',
      loggedAt: now.subtract(const Duration(hours: 2)),
    );
    await repo.addDementiaLog(
      type: 'Trinken',
      value: '300 ml Tee',
      note: 'Getraenk: Tee',
      loggedAt: now.subtract(const Duration(hours: 1)),
    );
    await repo.addDementiaLog(
      type: 'Mahlzeit',
      value: 'Mittagessen',
      note: 'Portion: Normal',
      loggedAt: now.subtract(const Duration(minutes: 30)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: DementiaSupportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demenz-Unterstützung'), findsOneWidget);
    expect(
      find.text('Erinnerungen & Protokolle lokal auf diesem Gerät'),
      findsOneWidget,
    );
    expect(find.text('550'), findsOneWidget);
    expect(find.text('ml getrunken'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Mahlzeiten'), findsOneWidget);
    expect(find.text('Getrunken (250ml)'), findsOneWidget);
    expect(find.text('Trinken detailliert'), findsOneWidget);
    expect(find.text('Mahlzeit gegessen'), findsOneWidget);
    expect(find.text('Routine erledigt'), findsOneWidget);
    expect(find.text('3 heute • 3 lokale Pflege-Logs'), findsOneWidget);
    expect(find.text('Heute protokolliert'), findsOneWidget);
    expect(find.text('Trinken: 300 ml Tee'), findsOneWidget);
    expect(find.text('Mahlzeit: Mittagessen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Für Betreuer & Familie'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Für Betreuer & Familie'), findsOneWidget);
  });
}
