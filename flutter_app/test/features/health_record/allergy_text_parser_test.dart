import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/health_record/domain/allergy_text_parser.dart';

void main() {
  const parser = AllergyTextParser();

  test('extracts medication allergy with severe reaction', () {
    final result = parser.parse(
      'Ich bin allergisch gegen Penicillin mit Atemnot und Schwellung',
    );

    expect(result.substance, 'Penicillin');
    expect(result.category, 'Medikament');
    expect(result.severity, 'Schwer');
    expect(result.reaction, 'Atemnot und Schwellung');
    expect(result.isComplete, isTrue);
  });

  test('extracts food allergy and life threatening severity', () {
    final result = parser.parse(
      'Allergie gegen Erdnuss, lebensbedrohlich, Reaktion ist Anaphylaxie',
    );

    expect(result.substance, 'Erdnuss');
    expect(result.category, 'Nahrungsmittel');
    expect(result.severity, 'Lebensbedrohlich');
    expect(result.reaction, 'Anaphylaxie');
  });

  test('reports missing allergen for incomplete text', () {
    final result = parser.parse('starker Ausschlag und Juckreiz');

    expect(result.isComplete, isFalse);
    expect(result.missingFields, ['Allergen']);
    expect(result.reaction, 'Hautausschlag, Juckreiz');
  });
}
