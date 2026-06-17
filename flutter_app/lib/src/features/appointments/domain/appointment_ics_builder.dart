import 'appointment.dart';

class AppointmentIcsBuilder {
  String build(List<Appointment> appointments, {DateTime? generatedAt}) {
    final stamp = _formatUtc(generatedAt ?? DateTime.now().toUtc());
    final events = appointments
        .map((appointment) {
          final start = appointment.startsAt.toUtc();
          final end = start.add(const Duration(hours: 1));
          final description = [
            if ((appointment.specialty ?? '').isNotEmpty)
              'Fachrichtung: ${appointment.specialty}',
            if ((appointment.reason ?? '').isNotEmpty)
              'Grund: ${appointment.reason}',
            if ((appointment.location ?? '').isNotEmpty)
              'Ort: ${appointment.location}',
            if ((appointment.notes ?? '').isNotEmpty)
              'Notizen: ${appointment.notes}',
          ].join('\n');
          return [
            'BEGIN:VEVENT',
            'UID:${_escapeText(appointment.id)}@gesundheitplus.app',
            'DTSTAMP:$stamp',
            'DTSTART:${_formatUtc(start)}',
            'DTEND:${_formatUtc(end)}',
            'SUMMARY:${_escapeText('Arzttermin: ${appointment.doctorName}')}',
            'DESCRIPTION:${_escapeText(description)}',
            'LOCATION:${_escapeText(appointment.location ?? '')}',
            'STATUS:${appointment.status == AppointmentStatus.confirmed ? 'CONFIRMED' : 'TENTATIVE'}',
            if (appointment.reminderEnabled) ...[
              'BEGIN:VALARM',
              'TRIGGER:-PT${appointment.reminderHoursBefore}H',
              'ACTION:DISPLAY',
              'DESCRIPTION:${_escapeText('Erinnerung: Termin bei ${appointment.doctorName}')}',
              'END:VALARM',
            ],
            'END:VEVENT',
          ].join('\r\n');
        })
        .join('\r\n');

    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Gesundheit Plus//Terminkalender//DE',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'X-WR-CALNAME:Gesundheit Plus Termine',
      'X-WR-TIMEZONE:Europe/Berlin',
      'X-WR-CALDESC:Ihre Arzttermine aus Gesundheit Plus',
      events,
      'END:VCALENDAR',
    ].where((line) => line.isNotEmpty).join('\r\n');
  }

  String _formatUtc(DateTime value) {
    final utc = value.toUtc();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  String _escapeText(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;');
  }
}
