import 'dart:io';

import '../../../core/storage/app_database.dart';

class LocalPrivacyRepository {
  LocalPrivacyRepository(this._db);

  final AppDatabase _db;

  Future<LocalPrivacySnapshot> snapshot() async {
    final counts = <String, int>{};
    for (final table in _db.allTables) {
      final rows = _db.select(
        'SELECT COUNT(*) AS count FROM ${table.actualTableName}',
      );
      counts[table.actualTableName] = rows.first['count'] as int;
    }
    final consent = _db.select(
      "SELECT ai_context_allowed FROM consent_settings WHERE id = 'default'",
    );
    return LocalPrivacySnapshot(
      tableCounts: counts,
      aiContextAllowed:
          consent.isNotEmpty && consent.first['ai_context_allowed'] == 1,
    );
  }

  Future<void> setAiContextAllowed(bool allowed) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO consent_settings (
        id, ai_context_allowed, ai_consent_granted_at, updated_at
      )
      VALUES ('default', ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        ai_context_allowed = excluded.ai_context_allowed,
        ai_consent_granted_at = excluded.ai_consent_granted_at,
        updated_at = excluded.updated_at
      ''',
      [allowed ? 1 : 0, allowed ? now : null, now],
    );
  }

  Future<void> clearAllLocalData() async {
    final documentRows = _db.select('SELECT local_path FROM health_documents');
    for (final row in documentRows) {
      final path = row['local_path'] as String?;
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    }
    for (final table in _db.allTables.reversed) {
      _db.execute('DELETE FROM ${table.actualTableName}');
    }
  }
}

class LocalPrivacySnapshot {
  const LocalPrivacySnapshot({
    required this.tableCounts,
    required this.aiContextAllowed,
  });

  final Map<String, int> tableCounts;
  final bool aiContextAllowed;

  int get totalRows =>
      tableCounts.values.fold<int>(0, (total, count) => total + count);
}
