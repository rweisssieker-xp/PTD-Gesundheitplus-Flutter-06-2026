import 'package:flutter_test/flutter_test.dart';
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
}
