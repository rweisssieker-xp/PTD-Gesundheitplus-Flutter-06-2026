import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication_intake_text_parser.dart';

void main() {
  const parser = MedicationIntakeTextParser();

  test('detects taken intake confirmation', () {
    final result = parser.parse('Ja, ich habe das Medikament eingenommen');

    expect(result.decision, MedicationIntakeDecision.taken);
    expect(result.note, 'Ja, ich habe das Medikament eingenommen');
  });

  test('detects skipped intake confirmation', () {
    final result = parser.parse('Nein, ich habe es vergessen');

    expect(result.decision, MedicationIntakeDecision.skipped);
  });

  test('returns unknown for unclear input', () {
    final result = parser.parse('Vielleicht später');

    expect(result.decision, MedicationIntakeDecision.unknown);
  });
}
