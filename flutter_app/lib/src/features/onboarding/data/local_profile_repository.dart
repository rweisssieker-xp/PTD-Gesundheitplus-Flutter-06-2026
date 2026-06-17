import '../../../core/storage/app_database.dart';
import '../../privacy/data/local_privacy_repository.dart';

class LocalProfileRepository {
  LocalProfileRepository(this._db);

  final AppDatabase _db;

  Future<void> saveProfile({
    required String fullName,
    DateTime? dateOfBirth,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO local_profiles (id, full_name, date_of_birth, notes, created_at, updated_at)
      VALUES ('default', ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        full_name = excluded.full_name,
        date_of_birth = excluded.date_of_birth,
        notes = excluded.notes,
        updated_at = excluded.updated_at
      ''',
      [fullName, dateOfBirth?.toIso8601String(), notes, now, now],
    );
  }

  Future<LocalProfile?> getProfile() async {
    final rows = _db.select('''
      SELECT full_name, date_of_birth, notes
      FROM local_profiles
      WHERE id = 'default'
      LIMIT 1
      ''');
    if (rows.isEmpty) return null;
    final row = rows.first;
    return LocalProfile(
      fullName: row['full_name'] as String? ?? '',
      dateOfBirth: _date(row['date_of_birth']),
      notes: row['notes'] as String?,
    );
  }

  Future<OnboardingSnapshot> snapshot() async {
    final profile = await getProfile();
    final privacy = await LocalPrivacyRepository(_db).snapshot();
    return OnboardingSnapshot(
      hasProfile: profile != null && profile.fullName.trim().isNotEmpty,
      aiContextAllowed: privacy.aiContextAllowed,
    );
  }

  DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }
}

class LocalProfile {
  const LocalProfile({required this.fullName, this.dateOfBirth, this.notes});

  final String fullName;
  final DateTime? dateOfBirth;
  final String? notes;
}

class OnboardingSnapshot {
  const OnboardingSnapshot({
    required this.hasProfile,
    required this.aiContextAllowed,
  });

  final bool hasProfile;
  final bool aiContextAllowed;
}
