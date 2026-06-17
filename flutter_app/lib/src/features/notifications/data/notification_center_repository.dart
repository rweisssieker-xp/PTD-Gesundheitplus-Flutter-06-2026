import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';

class NotificationCenterRepository {
  NotificationCenterRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> addNotification({
    required String title,
    required String body,
    required String category,
    DateTime? scheduledAt,
  }) async {
    _db.execute(
      '''
      INSERT INTO notifications (id, title, body, category, read, scheduled_at, created_at)
      VALUES (?, ?, ?, ?, 0, ?, ?)
      ''',
      [
        _uuid.v4(),
        title,
        body,
        category,
        scheduledAt?.toIso8601String(),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  Future<List<LocalNotificationItem>> listNotifications() async {
    final rows = _db.select('''
      SELECT id, title, body, category, read, scheduled_at, created_at
      FROM notifications
      ORDER BY created_at DESC
      ''');
    return rows
        .map(
          (row) => LocalNotificationItem(
            id: row['id'] as String,
            title: row['title'] as String,
            body: row['body'] as String,
            category: row['category'] as String,
            read: row['read'] == 1,
            scheduledAt: _date(row['scheduled_at']),
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<void> markRead(String id) async {
    _db.execute('UPDATE notifications SET read = 1 WHERE id = ?', [id]);
  }

  DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

class LocalNotificationItem {
  const LocalNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.read,
    this.scheduledAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final bool read;
  final DateTime? scheduledAt;
  final DateTime createdAt;
}
