import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication_text_parser.dart';

void main() {
  const parser = MedicationTextParser();

  test('extracts medication fields from spoken style text', () {
    final result = parser.parse(
      'Ich nehme Ramipril 5mg einmal täglich morgens wegen Blutdruck verschrieben von Hausarzt',
    );

    expect(result.name, 'Ramipril');
    expect(result.dosage, '5 mg');
    expect(result.frequency, '1x taeglich');
    expect(result.reason, 'Blutdruck');
    expect(result.prescribedBy, 'Hausarzt');
    expect(result.reminderTimes, ['08:00']);
    expect(result.isComplete, isTrue);
  });

  test('extracts daily time reminders and dosage unit', () {
    final result = parser.parse(
      'Metformin 500 mg zweimal täglich um 08:00 und um 20:00 Uhr gegen Diabetes',
    );

    expect(result.name, 'Metformin');
    expect(result.dosage, '500 mg');
    expect(result.frequency, '2x taeglich');
    expect(result.reason, 'Diabetes');
    expect(result.reminderTimes, ['08:00', '20:00']);
  });

  test('reports missing required fields for incomplete text', () {
    final result = parser.parse('wegen Schmerzen');

    expect(result.isComplete, isFalse);
    expect(result.missingFields, ['Medikament', 'Dosierung', 'Haeufigkeit']);
  });
}
