import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/app/gesundheit_app.dart';
import 'package:gesundheitplus/src/core/security/app_lock_service.dart';
import 'package:gesundheitplus/src/core/security/security_providers.dart';

void main() {
  testWidgets('renders Gesundheit Plus shell with red header', (tester) async {
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

    expect(find.text('Gesundheit Plus'), findsOneWidget);
    expect(find.byTooltip('Sprache'), findsOneWidget);
    final container = tester.widget<Container>(
      find.byKey(const Key('gp-header-red-border')),
    );
    expect(container.color, const Color(0xFFDC2626));
  });

  testWidgets('locks app shell when PIN exists', (tester) async {
    final store = InMemorySecretStore();
    final lock = AppLockService(
      store: store,
      biometricAuthenticator: const DisabledBiometricAuthenticator(),
    );
    await lock.setPin('123456');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLockServiceProvider.overrideWithValue(lock)],
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
  });
}
