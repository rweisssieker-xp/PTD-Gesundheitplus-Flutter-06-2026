import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/app/app_router.dart';
import 'package:gesundheitplus/src/app/gesundheit_app.dart';
import 'package:gesundheitplus/src/core/security/app_lock_service.dart';
import 'package:gesundheitplus/src/core/security/security_providers.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native app flow opens core local feature routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

    if (find.text('Lokal speichern wählen').evaluate().isNotEmpty) {
      expect(find.text('Nur auf diesem Gerät'), findsOneWidget);
      await tester.ensureVisible(find.text('Lokal speichern wählen'));
      await tester.tap(find.text('Lokal speichern wählen'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Dokument scannen'), findsOneWidget);

    final routeExpectations = <String, String>{
      '/medication': 'Medikation',
      '/appointments': 'Lokale Termineingabe',
      '/emergency/offline': 'Offline-Notfalldaten',
      '/documents/scan': 'Dokument scannen',
      '/privacy': 'Datenschutz & Sicherheit',
      '/ai/coach': 'KI-Kontextfreigabe ist aus',
    };

    for (final entry in routeExpectations.entries) {
      appRouter.go(entry.key);
      await tester.pumpAndSettle();
      expect(
        find.textContaining(entry.value),
        findsWidgets,
        reason: '${entry.key} should render ${entry.value}',
      );
    }
  });
}
