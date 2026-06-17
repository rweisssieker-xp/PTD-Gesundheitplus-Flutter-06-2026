class ReminderRule {
  const ReminderRule._({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.category,
  });

  factory ReminderRule.medication({
    required String id,
    required String title,
    required int hour,
    required int minute,
  }) {
    return ReminderRule._(
      id: id,
      title: title,
      hour: hour,
      minute: minute,
      category: 'medication',
    );
  }

  final String id;
  final String title;
  final int hour;
  final int minute;
  final String category;

  DateTime nextOccurrence(DateTime now) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    if (today.isAfter(now)) {
      return today;
    }
    return today.add(const Duration(days: 1));
  }
}
