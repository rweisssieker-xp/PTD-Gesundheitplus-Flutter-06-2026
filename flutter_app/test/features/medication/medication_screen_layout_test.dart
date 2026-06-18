import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
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
    expect(
      find.text('Noch keine Medikamente hinzugefuegt', skipOffstage: false),
      findsOneWidget,
    );
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
