import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/ai/ai_context_builder.dart';

void main() {
  test('blocks context when consent is false', () {
    final builder = AiContextBuilder();
    expect(
      () => builder.build(
        consentAllowed: false,
        medications: const ['Ramipril 5mg'],
        allergies: const ['Penicillin'],
        diagnoses: const ['Hypertonie'],
        healthPasses: const ['Implantatpass Knieprothese'],
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('builds bounded health context when consent is true', () {
    final builder = AiContextBuilder();
    final context = builder.build(
      consentAllowed: true,
      medications: const ['Ramipril 5mg'],
      allergies: const ['Penicillin'],
      diagnoses: const ['Hypertonie'],
      healthPasses: const ['Implantatpass Knieprothese MediCorp K-42'],
    );
    expect(context, contains('Aktive Medikamente: Ramipril 5mg'));
    expect(context, contains('Allergien: Penicillin'));
    expect(context, contains('Diagnosen: Hypertonie'));
    expect(
      context,
      contains('Gesundheitspaesse: Implantatpass Knieprothese MediCorp K-42'),
    );
  });
}
