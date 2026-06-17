import '../../../core/storage/app_database.dart';

class CommunicationPreferencesRepository {
  CommunicationPreferencesRepository(this._db);

  final AppDatabase _db;

  Future<CommunicationPreference> get(String channel) async {
    final rows = _db.select(
      '''
      SELECT id, channel, enabled, display_name, target_value, notes
      FROM communication_preferences
      WHERE channel = ?
      LIMIT 1
      ''',
      [channel],
    );
    if (rows.isEmpty) {
      return CommunicationPreference(
        id: channel,
        channel: channel,
        enabled: false,
      );
    }
    final row = rows.first;
    return CommunicationPreference(
      id: row['id'] as String,
      channel: row['channel'] as String,
      enabled: row['enabled'] == 1,
      displayName: row['display_name'] as String?,
      targetValue: row['target_value'] as String?,
      notes: row['notes'] as String?,
    );
  }

  Future<void> save({
    required String channel,
    required bool enabled,
    String? displayName,
    String? targetValue,
    String? notes,
  }) async {
    _db.execute(
      '''
      INSERT INTO communication_preferences (
        id, channel, enabled, display_name, target_value, notes, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        enabled = excluded.enabled,
        display_name = excluded.display_name,
        target_value = excluded.target_value,
        notes = excluded.notes,
        updated_at = excluded.updated_at
      ''',
      [
        channel,
        channel,
        enabled ? 1 : 0,
        displayName,
        targetValue,
        notes,
        DateTime.now().toIso8601String(),
      ],
    );
  }
}

class CommunicationPreference {
  const CommunicationPreference({
    required this.id,
    required this.channel,
    required this.enabled,
    this.displayName,
    this.targetValue,
    this.notes,
  });

  final String id;
  final String channel;
  final bool enabled;
  final String? displayName;
  final String? targetValue;
  final String? notes;
}
