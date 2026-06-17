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
}
