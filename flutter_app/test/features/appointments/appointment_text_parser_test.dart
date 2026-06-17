import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/appointments/domain/appointment_text_parser.dart';

void main() {
  const parser = AppointmentTextParser();

  test('extracts appointment fields from spoken style text', () {
    final result = parser.parse(
      'Ich habe morgen um 14:30 einen Termin bei Dr. Schmidt wegen Kontrolle in Berlin Mitte',
      now: DateTime(2026, 6, 17, 8),
    );

    expect(result.doctorName, 'Dr. Schmidt');
    expect(result.date, DateTime(2026, 6, 18));
    expect(result.time, '14:30');
    expect(result.location, 'Berlin Mitte');
    expect(result.reason, 'Kontrolle');
    expect(result.isComplete, isTrue);
  });

  test('extracts german date and known specialty', () {
    final result = parser.parse(
      'Termin bei Hausarzt am 21.06.2026 um 9 Uhr zur Blutkontrolle',
      now: DateTime(2026, 6, 17),
    );

    expect(result.doctorName, 'Hausarzt');
    expect(result.specialty, 'Allgemeinmedizin');
    expect(result.date, DateTime(2026, 6, 21));
    expect(result.time, '09:00');
    expect(result.reason, 'Blutkontrolle');
  });

  test('reports missing required fields for incomplete text', () {
    final result = parser.parse(
      'Kontrolle wegen Schmerzen',
      now: DateTime(2026, 6, 17),
    );

    expect(result.isComplete, isFalse);
    expect(result.missingFields, ['Arzt / Behandler', 'Datum', 'Uhrzeit']);
  });
}
