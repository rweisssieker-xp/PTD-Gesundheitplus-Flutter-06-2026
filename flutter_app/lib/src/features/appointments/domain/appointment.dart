class Appointment {
  const Appointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.location,
    required this.reason,
    required this.reminderEnabled,
    required this.reminderHoursBefore,
    required this.notes,
    required this.status,
  });

  final String id;
  final String doctorName;
  final String? specialty;
  final DateTime date;
  final String time;
  final String? location;
  final String? reason;
  final bool reminderEnabled;
  final int reminderHoursBefore;
  final String? notes;
  final AppointmentStatus status;

  DateTime get startsAt {
    final parts = time.split(':');
    final hour = parts.isEmpty ? 0 : int.tryParse(parts[0]) ?? 0;
    final minute = parts.length < 2 ? 0 : int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Appointment copyWith({AppointmentStatus? status}) {
    return Appointment(
      id: id,
      doctorName: doctorName,
      specialty: specialty,
      date: date,
      time: time,
      location: location,
      reason: reason,
      reminderEnabled: reminderEnabled,
      reminderHoursBefore: reminderHoursBefore,
      notes: notes,
      status: status ?? this.status,
    );
  }
}

enum AppointmentStatus {
  planned('Geplant'),
  confirmed('Bestaetigt'),
  completed('Abgeschlossen'),
  cancelled('Abgesagt');

  const AppointmentStatus(this.label);

  final String label;

  static AppointmentStatus fromStorage(String value) {
    return AppointmentStatus.values.firstWhere(
      (status) => status.label == value || status.name == value,
      orElse: () => AppointmentStatus.planned,
    );
  }
}
