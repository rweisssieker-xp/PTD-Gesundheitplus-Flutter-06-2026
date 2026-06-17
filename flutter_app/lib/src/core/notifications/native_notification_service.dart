import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_scheduler.dart';

class NativeNotificationService {
  NativeNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> scheduleDailyReminder(
    ScheduledReminder reminder, {
    required String body,
  }) async {
    await scheduleReminder(reminder, body: body, repeatDaily: true);
  }

  Future<void> scheduleReminder(
    ScheduledReminder reminder, {
    required String body,
    bool repeatDaily = false,
  }) async {
    await initialize();
    final status = await Permission.notification.request();
    if (!status.isGranted && !status.isLimited) {
      throw StateError('Notification permission is not granted');
    }
    await _plugin.zonedSchedule(
      _stableNotificationId(reminder.id),
      reminder.title,
      body,
      tz.TZDateTime.from(reminder.scheduledAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          reminder.category,
          _categoryName(reminder.category),
          channelDescription: 'Lokale Gesundheit Plus Erinnerungen',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      payload: reminder.id,
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    await initialize();
    await _plugin.cancel(_stableNotificationId(reminderId));
  }

  Future<void> cancelMedicationReminders({
    required String medicationId,
    required List<String> reminderTimes,
  }) async {
    final scheduler = NotificationScheduler();
    final reminders = scheduler.medicationReminders(
      medicationId: medicationId,
      medicationName: medicationId,
      reminderTimes: reminderTimes,
      now: DateTime.now(),
    );
    for (final reminder in reminders) {
      await cancelReminder(reminder.id);
    }
  }

  Future<void> cancelAppointmentReminder(String appointmentId) {
    return cancelReminder('appointment-$appointmentId');
  }

  int _stableNotificationId(String value) {
    final bytes = md5.convert(utf8.encode(value)).bytes;
    return bytes.take(4).fold<int>(0, (id, byte) => (id << 8) | byte) &
        0x7fffffff;
  }

  String _categoryName(String category) {
    return switch (category) {
      'medication' => 'Medikation',
      'appointment' => 'Termine',
      'prevention' => 'Vorsorge',
      _ => 'Gesundheit Plus',
    };
  }
}
