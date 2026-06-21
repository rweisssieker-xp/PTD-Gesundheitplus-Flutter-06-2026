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
    LocalNotificationStatus status = LocalNotificationStatus.active,
    String? statusDetail,
  }) async {
    _db.execute(
      '''
      INSERT INTO notifications (
        id, title, body, category, read, scheduled_at, status, status_detail,
        created_at
      )
      VALUES (?, ?, ?, ?, 0, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        title,
        body,
        category,
        scheduledAt?.toIso8601String(),
        status.storageValue,
        statusDetail,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  Future<ProactiveHealthCheckResult> runProactiveHealthChecks({
    DateTime? now,
  }) async {
    final checkedAt = now ?? DateTime.now();
    var created = 0;
    created += await _checkMedicationRefills(checkedAt);
    created += await _checkHighRiskInteractions(checkedAt);
    created += await _checkEmergencyContacts(checkedAt);
    created += await _checkLocalProfile(checkedAt);
    return ProactiveHealthCheckResult(createdNotifications: created);
  }

  Future<List<LocalNotificationItem>> listNotifications() async {
    final rows = _db.select('''
      SELECT id, title, body, category, read, scheduled_at, created_at
           , status, status_detail
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
            status: LocalNotificationStatus.fromStorage(
              row['status'] as String?,
            ),
            statusDetail: row['status_detail'] as String?,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<void> markRead(String id) async {
    _db.execute('UPDATE notifications SET read = 1 WHERE id = ?', [id]);
  }

  Future<void> markAllRead() async {
    _db.execute('UPDATE notifications SET read = 1 WHERE read = 0');
  }

  Future<void> deleteNotification(String id) async {
    _db.execute('DELETE FROM notifications WHERE id = ?', [id]);
  }

  Future<void> deleteAll() async {
    _db.execute('DELETE FROM notifications');
  }

  Future<int> _checkMedicationRefills(DateTime now) async {
    final rows = _db.select('''
      SELECT name, dosage, start_date, supply_duration_days,
             refill_reminder_days
      FROM medications
      WHERE active = 1
        AND start_date IS NOT NULL
        AND supply_duration_days IS NOT NULL
      ''');
    var created = 0;
    for (final row in rows) {
      final startDate = DateTime.tryParse(row['start_date'] as String? ?? '');
      final supplyDuration = row['supply_duration_days'] as int?;
      if (startDate == null || supplyDuration == null || supplyDuration <= 0) {
        continue;
      }
      final reminderDays = row['refill_reminder_days'] as int? ?? 7;
      final daysRemaining = supplyDuration - now.difference(startDate).inDays;
      if (daysRemaining <= reminderDays && daysRemaining > 0) {
        final name = row['name'] as String;
        final dosage = row['dosage'] as String?;
        final details = [
          name,
          if (dosage != null && dosage.trim().isNotEmpty) dosage,
          'Vorrat reicht noch $daysRemaining Tag${daysRemaining == 1 ? '' : 'e'}. Bitte Rezept oder Nachschub planen.',
        ].join(' - ');
        created += await _addNotificationOncePerDay(
          title: 'Medikament bald aufgebraucht',
          body: details,
          category: 'medication_refill',
          now: now,
          dedupeKey: 'refill:$name',
        );
      }
    }
    return created;
  }

  Future<int> _checkHighRiskInteractions(DateTime now) async {
    final rows = _db.select('''
      SELECT id
      FROM medication_interaction_checks
      WHERE risk_level = 'hoch'
      ORDER BY checked_at DESC
      LIMIT 1
      ''');
    if (rows.isEmpty) return 0;
    return _addNotificationOncePerDay(
      title: 'Medikamenten-Interaktion erkannt',
      body:
          'Ein lokaler Wechselwirkungscheck ist als hohes Risiko markiert. Bitte aerztlich pruefen.',
      category: 'warning',
      now: now,
      dedupeKey: 'high_risk_interaction',
    );
  }

  Future<int> _checkEmergencyContacts(DateTime now) async {
    final contacts = _db.select('SELECT verified FROM emergency_contacts');
    if (contacts.isEmpty) {
      return _addNotificationOncePerDay(
        title: 'Keine Notfallkontakte eingerichtet',
        body:
            'Fuer Ihre Sicherheit: Bitte richten Sie mindestens einen lokalen Notfallkontakt ein.',
        category: 'warning',
        now: now,
        dedupeKey: 'missing_emergency_contacts',
      );
    }
    if (!contacts.every((row) => row['verified'] != 1)) return 0;
    return _addNotificationOncePerDay(
      title: 'Notfallkontakte verifizieren',
      body:
          '${contacts.length} Kontakt(e) sind noch nicht verifiziert. Pruefen Sie, ob Notfallnachrichten ankommen.',
      category: 'info',
      now: now,
      dedupeKey: 'unverified_emergency_contacts',
    );
  }

  Future<int> _checkLocalProfile(DateTime now) async {
    final rows = _db.select(
      "SELECT full_name FROM local_profiles WHERE id = 'default' LIMIT 1",
    );
    final name = rows.isEmpty ? null : rows.first['full_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return 0;
    return _addNotificationOncePerDay(
      title: 'Notfallprofil vervollstaendigen',
      body:
          'Ergaenzen Sie Ihr lokales Profil, damit Offline-Notfallinformationen aussagekraeftiger sind.',
      category: 'info',
      now: now,
      dedupeKey: 'missing_local_profile',
    );
  }

  Future<int> _addNotificationOncePerDay({
    required String title,
    required String body,
    required String category,
    required DateTime now,
    required String dedupeKey,
  }) async {
    final dayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final existing = _db.select(
      '''
      SELECT id
      FROM notifications
      WHERE category = ?
        AND title = ?
        AND body LIKE ?
        AND created_at >= ?
      LIMIT 1
      ''',
      [category, title, '%[$dedupeKey]%', dayStart],
    );
    if (existing.isNotEmpty) return 0;
    await addNotification(
      title: title,
      body: '$body [$dedupeKey]',
      category: category,
    );
    return 1;
  }

  DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

class ProactiveHealthCheckResult {
  const ProactiveHealthCheckResult({required this.createdNotifications});

  final int createdNotifications;
}

class LocalNotificationItem {
  const LocalNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.read,
    this.status = LocalNotificationStatus.active,
    this.statusDetail,
    this.scheduledAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final bool read;
  final LocalNotificationStatus status;
  final String? statusDetail;
  final DateTime? scheduledAt;
  final DateTime createdAt;

  String get displayBody => body.replaceFirst(RegExp(r'\s*\[[^\]]+\]$'), '');
}

enum LocalNotificationStatus {
  active('active', 'Aktiv'),
  permissionMissing('permission_missing', 'Berechtigung fehlt'),
  systemBlocked('system_blocked', 'System blockiert'),
  needsReschedule('needs_reschedule', 'Neu planen'),
  inactive('inactive', 'Inaktiv');

  const LocalNotificationStatus(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static LocalNotificationStatus fromStorage(String? value) {
    return LocalNotificationStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => LocalNotificationStatus.active,
    );
  }
}
