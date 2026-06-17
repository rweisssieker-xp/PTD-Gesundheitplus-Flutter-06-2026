import '../../../core/storage/app_database.dart';

class StorageModeRepository {
  StorageModeRepository(this._db);

  final AppDatabase _db;

  bool isLocalModeSelected() {
    final rows = _db.select(
      "SELECT id FROM consent_settings WHERE id = 'storage_mode_local'",
    );
    return rows.isNotEmpty;
  }

  Future<void> selectLocalMode() async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO consent_settings (
        id, ai_context_allowed, ai_consent_granted_at, updated_at
      )
      VALUES ('storage_mode_local', 0, NULL, ?)
      ON CONFLICT(id) DO UPDATE SET updated_at = excluded.updated_at
      ''',
      [now],
    );
  }
}
