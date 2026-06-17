import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/security/app_lock_service.dart';
import 'package:gesundheitplus/src/core/security/security_providers.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('onboarding requests local notification permission on save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    var notificationRequested = false;

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
        child: MaterialApp(
          home: OnboardingScreen(
            requestNotifications: () async {
              notificationRequested = true;
              return false;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lokale Erinnerungen erlauben'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Max Patient');
    await tester.tap(find.text('Einrichtung speichern'));
    await tester.pumpAndSettle();

    expect(notificationRequested, isTrue);
    expect(find.text('Einrichtung gespeichert'), findsOneWidget);
    expect(find.text('Erinnerungen noch nicht erlaubt'), findsOneWidget);
  });
}
