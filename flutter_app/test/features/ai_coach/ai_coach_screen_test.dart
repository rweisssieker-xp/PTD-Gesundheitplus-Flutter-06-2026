import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/ai_coach/presentation/ai_coach_screen.dart';
import 'package:gesundheitplus/src/features/privacy/data/local_privacy_repository.dart';
import 'package:gesundheitplus/src/features/privacy/presentation/privacy_screen.dart';

void main() {
  testWidgets('uses AI after consent and blocks context after revoke', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    final privacy = LocalPrivacyRepository(db);
    await privacy.setAiContextAllowed(true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: AiCoachScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('KI-Kontextfreigabe ist aktiv'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Frage'),
      'Termin planen',
    );
    await tester.tap(find.byTooltip('Senden'));
    await tester.pumpAndSettle();

    expect(find.text('Termin planen'), findsOneWidget);
    expect(find.textContaining('Pruefe deine lokalen Termine'), findsOneWidget);
    expect(find.textContaining('lokal auf dem Gerät erzeugt'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: PrivacyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final consentSwitch = find.byType(Switch).first;
    expect(tester.widget<Switch>(consentSwitch).value, isTrue);
    await tester.tap(consentSwitch);
    await tester.pumpAndSettle();
    expect((await privacy.snapshot()).aiContextAllowed, isFalse);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: AiCoachScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('KI-Kontextfreigabe ist aus'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Frage'),
      'Medikamente prüfen',
    );
    await tester.tap(find.byTooltip('Senden'));
    await tester.pumpAndSettle();

    expect(find.text('Medikamente prüfen'), findsOneWidget);
    expect(find.textContaining('Bitte aktiviere zuerst'), findsOneWidget);
    expect(
      find.textContaining('Gesundheitsdaten bleiben lokal'),
      findsOneWidget,
    );
  });
}
