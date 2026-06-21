import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/app/gesundheit_app.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/core/security/app_lock_service.dart';
import 'package:gesundheitplus/src/core/security/security_providers.dart';
import 'package:gesundheitplus/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gesundheitplus/src/shared_ui/gp_icons.dart';

void main() {
  test('shared icons use the original PWA Lucide style', () {
    expect(GpIcons.anamnesis.fontFamily, 'Lucide');
    expect(GpIcons.aiCoach.fontFamily, 'Lucide');
    expect(GpIcons.settings.fontFamily, 'Lucide');
  });

  testWidgets('renders Gesundheit Plus shell with red header', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
          appLockServiceProvider.overrideWithValue(
            AppLockService(
              store: InMemorySecretStore(),
              biometricAuthenticator: const DisabledBiometricAuthenticator(),
            ),
          ),
        ],
        child: const GesundheitApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gesundheit Plus'), findsOneWidget);
    expect(find.text('Nur auf diesem Gerät'), findsOneWidget);
    expect(find.text('Cloud-Synchronisation'), findsOneWidget);
    expect(find.text('In der nativen App deaktiviert'), findsOneWidget);
    expect(find.text('Cloud-Sync nicht aktiv'), findsOneWidget);
    expect(find.text('Cloud-Sync wählen'), findsNothing);
    await tester.ensureVisible(find.text('Lokal speichern wählen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lokal speichern wählen'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sprache'), findsOneWidget);
    expect(find.text('Dokument scannen'), findsOneWidget);
    final container = tester.widget<Container>(
      find.byKey(const Key('gp-header-red-border')),
    );
    expect(container.color, const Color(0xFFDC2626));
  });

  testWidgets('locks app shell when PIN exists', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final store = InMemorySecretStore();
    final lock = AppLockService(
      store: store,
      biometricAuthenticator: const DisabledBiometricAuthenticator(),
    );
    await lock.setPin('123456');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
          appLockServiceProvider.overrideWithValue(lock),
        ],
        child: const GesundheitApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gesundheit Plus entsperren'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Entsperren'));
    await tester.pumpAndSettle();

    expect(find.text('Gesundheit Plus'), findsOneWidget);
    expect(find.text('Gesundheit Plus entsperren'), findsNothing);
    expect(find.text('Nur auf diesem Gerät'), findsOneWidget);
  });

  testWidgets('language selector persists and translates dashboard labels', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sprache'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('English'));
    await tester.pumpAndSettle();

    expect(find.text('Scan Document'), findsOneWidget);
  });

  testWidgets('dashboard grids keep PWA spacing without implicit padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: const MaterialApp(home: DashboardScreen())),
    );
    await tester.pumpAndSettle();

    final grids = tester.widgetList<GridView>(find.byType(GridView)).toList();

    expect(grids.length, greaterThanOrEqualTo(2));
    expect(grids.every((grid) => grid.padding == EdgeInsets.zero), isTrue);
  });

  testWidgets('dashboard footer stays in the scroll flow like the PWA', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: const MaterialApp(home: DashboardScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demo / Onboarding starten'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -1800));
    await tester.pumpAndSettle();

    expect(find.text('Demo / Onboarding starten'), findsOneWidget);
    expect(find.text('Eine Initiative für Ihre Gesundheit'), findsOneWidget);
  });
}
