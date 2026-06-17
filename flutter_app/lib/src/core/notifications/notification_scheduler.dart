import 'reminder_rule.dart';

class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.category,
    required this.scheduledAt,
  });

  final String id;
  final String title;
  final String category;
  final DateTime scheduledAt;
}

class NotificationScheduler {
  ScheduledReminder buildScheduledReminder(ReminderRule rule, DateTime now) {
    return ScheduledReminder(
      id: rule.id,
      title: rule.title,
      category: rule.category,
      scheduledAt: rule.nextOccurrence(now),
    );
  }

  List<ScheduledReminder> medicationReminders({
    required String medicationId,
    required String medicationName,
    required List<String> reminderTimes,
    required DateTime now,
  }) {
    return reminderTimes
        .map(_parseTime)
        .whereType<({int hour, int minute})>()
        .map(
          (time) => buildScheduledReminder(
            ReminderRule.medication(
              id: '$medicationId-${time.hour}-${time.minute}',
              title: '$medicationName einnehmen',
              hour: time.hour,
              minute: time.minute,
            ),
            now,
          ),
        )
        .toList();
  }

  ScheduledReminder? appointmentReminder({
    required String appointmentId,
    required String doctorName,
    required DateTime startsAt,
    required int hoursBefore,
    required DateTime now,
  }) {
    final scheduledAt = startsAt.subtract(Duration(hours: hoursBefore));
    if (!scheduledAt.isAfter(now)) return null;
    return ScheduledReminder(
      id: 'appointment-$appointmentId',
      title: 'Termin: $doctorName',
      category: 'appointment',
      scheduledAt: scheduledAt,
    );
  }

  ({int hour, int minute})? _parseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour: hour, minute: minute);
  }
}
