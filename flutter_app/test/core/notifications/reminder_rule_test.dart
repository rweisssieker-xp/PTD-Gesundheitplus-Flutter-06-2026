import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/notifications/notification_scheduler.dart';
import 'package:gesundheitplus/src/core/notifications/reminder_rule.dart';

void main() {
  test('creates medication reminder occurrence for today', () {
    final rule = ReminderRule.medication(
      id: 'med-1',
      title: 'Ramipril einnehmen',
      hour: 8,
      minute: 30,
    );
    final occurrence = rule.nextOccurrence(DateTime(2026, 6, 17, 7));
    expect(occurrence, DateTime(2026, 6, 17, 8, 30));
  });

  test('rolls medication reminder to tomorrow when time passed', () {
    final rule = ReminderRule.medication(
      id: 'med-1',
      title: 'Ramipril einnehmen',
      hour: 8,
      minute: 30,
    );
    final occurrence = rule.nextOccurrence(DateTime(2026, 6, 17, 9));
    expect(occurrence, DateTime(2026, 6, 18, 8, 30));
  });

  test('builds medication reminders from valid time strings', () {
    final reminders = NotificationScheduler().medicationReminders(
      medicationId: 'med-1',
      medicationName: 'Ramipril',
      reminderTimes: const ['08:00', '20:30', '25:00', 'abc'],
      now: DateTime(2026, 6, 17, 7),
    );

    expect(reminders, hasLength(2));
    expect(reminders.first.id, 'med-1-8-0');
    expect(reminders.first.title, 'Ramipril einnehmen');
    expect(reminders.last.scheduledAt, DateTime(2026, 6, 17, 20, 30));
  });

  test('builds appointment reminder before start time', () {
    final reminder = NotificationScheduler().appointmentReminder(
      appointmentId: 'appt-1',
      doctorName: 'Dr. Muster',
      startsAt: DateTime(2026, 6, 18, 9, 30),
      hoursBefore: 24,
      now: DateTime(2026, 6, 17, 8),
    );

    expect(reminder, isNotNull);
    expect(reminder!.id, 'appointment-appt-1');
    expect(reminder.title, 'Termin: Dr. Muster');
    expect(reminder.category, 'appointment');
    expect(reminder.scheduledAt, DateTime(2026, 6, 17, 9, 30));
  });

  test('skips appointment reminder when reminder time is in the past', () {
    final reminder = NotificationScheduler().appointmentReminder(
      appointmentId: 'appt-1',
      doctorName: 'Dr. Muster',
      startsAt: DateTime(2026, 6, 18, 9, 30),
      hoursBefore: 24,
      now: DateTime(2026, 6, 17, 10),
    );

    expect(reminder, isNull);
  });

  test('builds preventive care reminder for future due date', () {
    final reminder = NotificationScheduler().preventiveCareReminder(
      itemId: 'care-1',
      title: 'Hautscreening',
      dueAt: DateTime(2026, 7, 1, 9),
      now: DateTime(2026, 6, 17, 8),
    );

    expect(reminder, isNotNull);
    expect(reminder!.id, 'prevention-care-1');
    expect(reminder.title, 'Vorsorge: Hautscreening');
    expect(reminder.category, 'prevention');
    expect(reminder.scheduledAt, DateTime(2026, 7, 1, 9));
  });

  test('skips preventive care reminder when due date is in the past', () {
    final reminder = NotificationScheduler().preventiveCareReminder(
      itemId: 'care-1',
      title: 'Hautscreening',
      dueAt: DateTime(2026, 6, 1, 9),
      now: DateTime(2026, 6, 17, 8),
    );

    expect(reminder, isNull);
  });
}
