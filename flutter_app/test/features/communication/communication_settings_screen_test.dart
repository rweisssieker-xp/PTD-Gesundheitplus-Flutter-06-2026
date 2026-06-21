import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/platform/platform_handoff_service.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/communication/data/communication_preferences_repository.dart';
import 'package:gesundheitplus/src/features/communication/presentation/communication_settings_screen.dart';

void main() {
  testWidgets('telegram setup keeps original guided setup structure', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    final handoff = _FakeHandoff();
    addTearDown(db.close);

    await _pump(
      tester,
      db,
      CommunicationSettingsScreen(
        channel: 'telegram',
        title: 'Telegram-Setup',
        handoff: handoff,
      ),
    );

    expect(find.text('Telegram-Benachrichtigungen'), findsOneWidget);
    expect(find.text('Noch nicht verbunden'), findsOneWidget);
    expect(
      find.text('Vorteile von Telegram-Benachrichtigungen'),
      findsOneWidget,
    );
    expect(find.text('Öffnen Sie den Gesundheit Plus Bot'), findsOneWidget);
    expect(find.text('Starten Sie den Chat'), findsOneWidget);
    expect(find.text('/start'), findsOneWidget);
    expect(find.text('Holen Sie Ihre Chat-ID'), findsOneWidget);
    expect(find.text('/mychatid'), findsOneWidget);
    expect(find.text('Chat oder Benutzer speichern'), findsOneWidget);

    await tester.tap(find.text('Bot öffnen'));
    await tester.pump();
    expect(handoff.launched.single.scheme, 'tg');
    expect(handoff.launched.single.toString(), contains('GesundheitPlusBot'));

    await tester.enterText(
      find.widgetWithText(TextField, 'Telegram Chat-ID / Benutzer / Chat'),
      '@pflegekontakt',
    );
    await tester.ensureVisible(find.text('Verbinden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verbinden'));
    await tester.pumpAndSettle();

    final pref = await CommunicationPreferencesRepository(db).get('telegram');
    expect(pref.enabled, isTrue);
    expect(pref.targetValue, '@pflegekontakt');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await _pump(
      tester,
      db,
      CommunicationSettingsScreen(
        channel: 'telegram',
        title: 'Telegram-Setup',
        handoff: handoff,
      ),
    );

    expect(find.text('Telegram lokal aktiviert'), findsOneWidget);
    expect(find.text('Test-Nachricht senden'), findsOneWidget);

    await tester.tap(find.text('Test-Nachricht senden'));
    await tester.pump();
    expect(handoff.launched.last.scheme, 'tg');
    expect(handoff.launched.last.toString(), contains('pflegekontakt'));
  });

  testWidgets('sms setup offers local sms and whatsapp handoff tests', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    final handoff = _FakeHandoff();
    addTearDown(db.close);

    await _pump(
      tester,
      db,
      CommunicationSettingsScreen(
        channel: 'sms',
        title: 'SMS-Setup',
        handoff: handoff,
      ),
    );

    expect(find.text('SMS & WhatsApp Setup'), findsOneWidget);
    expect(find.text('Integration testen'), findsOneWidget);
    expect(find.text('Lokale Notfall-Kommunikation'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Telefonnummer').first,
      '+49 176 123456',
    );
    await tester.tap(find.text('SMS testen'));
    await tester.pumpAndSettle();
    expect(handoff.launched.single.scheme, 'sms');
    expect(find.text('Lokale Debug-Info'), findsOneWidget);
    expect(find.textContaining('E.164 Preview: +49176123456'), findsOneWidget);
    expect(find.text('SMS Handoff bereit'), findsOneWidget);

    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(handoff.launched.last.scheme, 'whatsapp');
    expect(handoff.launched.last.toString(), contains('49176123456'));
    expect(find.text('WhatsApp Handoff bereit'), findsOneWidget);
  });

  testWidgets('sms setup shows visible failure diagnostics', (tester) async {
    final db = AppDatabase.memory();
    final handoff = _FakeHandoff(launchResult: false);
    addTearDown(db.close);

    await _pump(
      tester,
      db,
      CommunicationSettingsScreen(
        channel: 'sms',
        title: 'SMS-Setup',
        handoff: handoff,
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Telefonnummer').first,
      '0151 2345678',
    );
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    expect(find.text('Lokale Debug-Info'), findsOneWidget);
    expect(find.textContaining('E.164 Preview: +491512345678'), findsOneWidget);
    expect(find.text('WhatsApp Handoff fehlgeschlagen'), findsOneWidget);
    expect(
      find.text('Keine passende WhatsApp-App auf diesem Gerät gefunden.'),
      findsOneWidget,
    );
  });
}

Future<void> _pump(WidgetTester tester, AppDatabase db, Widget child) async {
  tester.view.physicalSize = const Size(430, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
      child: MaterialApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeHandoff extends PlatformHandoffService {
  _FakeHandoff({this.launchResult = true});

  final bool launchResult;
  final launched = <Uri>[];

  @override
  Future<bool> launch(Uri uri) async {
    launched.add(uri);
    return launchResult;
  }
}
