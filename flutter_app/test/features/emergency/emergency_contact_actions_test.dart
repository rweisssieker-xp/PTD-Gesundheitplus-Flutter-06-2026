import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/platform/platform_handoff_service.dart';
import 'package:gesundheitplus/src/features/emergency/domain/emergency_profile.dart';
import 'package:gesundheitplus/src/features/emergency/presentation/emergency_contact_actions.dart';

void main() {
  testWidgets('shows failure when whatsapp handoff is unavailable', (
    tester,
  ) async {
    final handoff = _FakeHandoff(launchResult: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmergencyContactsSection(
            contacts: const [
              EmergencyContactSummary(name: 'Anna', phone: '+49176123456'),
            ],
            handoff: handoff,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('WhatsApp'));
    await tester.pumpAndSettle();

    expect(handoff.launched.single.scheme, 'whatsapp');
    expect(
      find.text(
        'WhatsApp konnte nicht geoeffnet werden. Nutzen Sie Teilen oder SMS.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shares emergency text through injected share sheet fallback', (
    tester,
  ) async {
    String? sharedText;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmergencyContactsSection(
            contacts: const [
              EmergencyContactSummary(name: 'Anna', phone: '+49176123456'),
            ],
            shareMessage: (text) async => sharedText = text,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Teilen'));
    await tester.pumpAndSettle();

    expect(sharedText, contains('Ich brauche Hilfe'));
    expect(sharedText, contains('Gesundheit Plus'));
  });

  testWidgets('launches telegram handoff when contact has messenger target', (
    tester,
  ) async {
    final handoff = _FakeHandoff(launchResult: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmergencyContactsSection(
            contacts: const [
              EmergencyContactSummary(
                name: 'Anna',
                phone: '+49176123456',
                messenger: '@anna_hilfe',
              ),
            ],
            handoff: handoff,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Telegram'));
    await tester.pumpAndSettle();

    expect(
      handoff.launched.single.toString(),
      'tg://resolve?domain=anna_hilfe',
    );
  });

  testWidgets('hides telegram handoff without messenger target', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmergencyContactsSection(
            contacts: [
              EmergencyContactSummary(name: 'Anna', phone: '+49176123456'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Telegram'), findsNothing);
  });
}

class _FakeHandoff extends PlatformHandoffService {
  _FakeHandoff({required this.launchResult});

  final bool launchResult;
  final List<Uri> launched = [];

  @override
  Future<bool> launch(Uri uri) async {
    launched.add(uri);
    return launchResult;
  }
}
