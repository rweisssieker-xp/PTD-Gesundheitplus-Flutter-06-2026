import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/appointments/domain/appointment.dart';
import 'package:gesundheitplus/src/features/appointments/domain/appointment_ics_builder.dart';

void main() {
  test('builds calendar export with appointment reminder', () {
    final ics = AppointmentIcsBuilder().build([
      Appointment(
        id: 'apt-1',
        doctorName: 'Dr. Muster',
        specialty: 'Allgemeinmedizin',
        date: DateTime(2026, 6, 18),
        time: '09:30',
        location: 'Praxis Mitte',
        reason: 'Kontrolle',
        reminderEnabled: true,
        reminderHoursBefore: 24,
        notes: 'Blutwerte mitbringen',
        status: AppointmentStatus.confirmed,
      ),
    ], generatedAt: DateTime.utc(2026, 6, 17, 10));

    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('UID:apt-1@gesundheitplus.app'));
    expect(ics, contains('DTSTAMP:20260617T100000Z'));
    expect(ics, contains('SUMMARY:Arzttermin: Dr. Muster'));
    expect(ics, contains('LOCATION:Praxis Mitte'));
    expect(ics, contains('STATUS:CONFIRMED'));
    expect(ics, contains('TRIGGER:-PT24H'));
    expect(ics, contains(r'Fachrichtung: Allgemeinmedizin\nGrund: Kontrolle'));
  });
}
