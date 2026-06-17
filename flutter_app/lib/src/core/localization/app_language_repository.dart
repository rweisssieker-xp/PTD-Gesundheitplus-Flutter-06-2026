import '../storage/app_database.dart';
import 'app_language.dart';

class AppLanguageRepository {
  AppLanguageRepository(this._db);

  final AppDatabase _db;

  Future<AppLanguage> read() async {
    final rows = _db.select('''
      SELECT language_code
      FROM app_preferences
      WHERE id = 'default'
      LIMIT 1
      ''');
    if (rows.isEmpty) return AppLanguage.de;
    return AppLanguage.fromCode(rows.first['language_code'] as String?);
  }

  Future<void> save(AppLanguage language) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO app_preferences (id, language_code, updated_at)
      VALUES ('default', ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        language_code = excluded.language_code,
        updated_at = excluded.updated_at
      ''',
      [language.code, now],
    );
  }
}
