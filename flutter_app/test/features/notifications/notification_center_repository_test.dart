import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/medication/data/medication_repository.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication.dart';
import 'package:gesundheitplus/src/features/notifications/data/notification_center_repository.dart';
import 'package:gesundheitplus/src/features/onboarding/data/local_profile_repository.dart';

void main() {
  test('stores and marks local notifications as read', () async {
    final db = AppDatabase.memory();
    final repo = NotificationCenterRepository(db);
    await repo.addNotification(
      title: 'Medikation',
      body: 'ASS einnehmen',
      category: 'medication',
      status: LocalNotificationStatus.needsReschedule,
      statusDetail: 'Zeit liegt in der Vergangenheit',
    );
    final created = await repo.listNotifications();
    expect(created.single.read, isFalse);
    expect(created.single.status, LocalNotificationStatus.needsReschedule);
    expect(created.single.statusDetail, 'Zeit liegt in der Vergangenheit');
    await repo.markRead(created.single.id);
    final read = await repo.listNotifications();
    expect(read.single.read, isTrue);
    db.close();
  });

  test('marks all read and deletes local notifications', () async {
    final db = AppDatabase.memory();
    final repo = NotificationCenterRepository(db);
    await repo.addNotification(
      title: 'Warnung',
      body: 'Pruefen',
      category: 'warning',
    );
    await repo.addNotification(
      title: 'Info',
      body: 'Hinweis',
      category: 'info',
    );
    await repo.markAllRead();
    expect((await repo.listNotifications()).every((item) => item.read), isTrue);
    final firstId = (await repo.listNotifications()).first.id;
    await repo.deleteNotification(firstId);
    expect(await repo.listNotifications(), hasLength(1));
    await repo.deleteAll();
    expect(await repo.listNotifications(), isEmpty);
    db.close();
  });

  test('creates proactive local health warnings once per day', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await LocalProfileRepository(
      db,
    ).saveProfile(fullName: 'Patient', dateOfBirth: DateTime(1970, 1, 1));
    await MedicationRepository(db).save(
      Medication(
        id: 'm1',
        name: 'Ramipril',
        dosage: '5mg',
        frequency: '1x taeglich',
        schedule: null,
        startDate: DateTime(2026, 6, 1),
        endDate: null,
        prescribedBy: null,
        reason: null,
        reminderEnabled: false,
        reminderTimes: const [],
        supplyDurationDays: 20,
        refillReminderDays: 7,
        notes: null,
        active: true,
      ),
    );

    final repo = NotificationCenterRepository(db);
    final first = await repo.runProactiveHealthChecks(
      now: DateTime(2026, 6, 17, 10),
    );
    final second = await repo.runProactiveHealthChecks(
      now: DateTime(2026, 6, 17, 11),
    );
    final notifications = await repo.listNotifications();

    expect(first.createdNotifications, 2);
    expect(second.createdNotifications, 0);
    expect(
      notifications.map((item) => item.title),
      contains('Medikament bald aufgebraucht'),
    );
    expect(
      notifications.map((item) => item.title),
      contains('Keine Notfallkontakte eingerichtet'),
    );
    expect(notifications.first.displayBody, isNot(contains('[refill:')));
  });
}
