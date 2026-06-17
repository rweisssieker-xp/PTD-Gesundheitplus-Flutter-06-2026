import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/notifications/data/notification_center_repository.dart';

void main() {
  test('stores and marks local notifications as read', () async {
    final db = AppDatabase.memory();
    final repo = NotificationCenterRepository(db);
    await repo.addNotification(
      title: 'Medikation',
      body: 'ASS einnehmen',
      category: 'medication',
    );
    final created = await repo.listNotifications();
    expect(created.single.read, isFalse);
    await repo.markRead(created.single.id);
    final read = await repo.listNotifications();
    expect(read.single.read, isTrue);
    db.close();
  });
}
