import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/appointments/domain/healthcare_professional_text_parser.dart';

void main() {
  const parser = HealthcareProfessionalTextParser();

  test('extracts healthcare professional fields from spoken style text', () {
    final result = parser.parse(
      'Mein Arzt Dr. Schmidt ist Kardiologe in Hauptstrasse 4 Berlin Telefon +49 30 123456 email praxis@example.de',
    );

    expect(result.name, 'Dr. Schmidt');
    expect(result.specialty, 'Kardiologie');
    expect(result.address, 'Hauptstrasse 4 Berlin');
    expect(result.phone, '+49 30 123456');
    expect(result.email, 'praxis@example.de');
    expect(result.isComplete, isTrue);
  });

  test('extracts specialty from explicit specialty phrase', () {
    final result = parser.parse(
      'Behandlerin Praxis am Park Fachrichtung Physiotherapie Telefon 0211 555777',
    );

    expect(result.name, 'Praxis am Park');
    expect(result.specialty, 'Physiotherapie');
    expect(result.phone, '0211 555777');
  });

  test('reports missing required fields for incomplete text', () {
    final result = parser.parse('Telefon 030 123456');

    expect(result.isComplete, isFalse);
    expect(result.missingFields, ['Name', 'Fachrichtung']);
    expect(result.phone, '030 123456');
  });
}
