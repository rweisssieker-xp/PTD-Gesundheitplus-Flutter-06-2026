import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/onboarding/data/local_profile_repository.dart';
import 'package:gesundheitplus/src/features/privacy/data/local_privacy_repository.dart';

void main() {
  test('stores local onboarding profile and reads snapshot', () async {
    final db = AppDatabase.memory();
    await LocalProfileRepository(
      db,
    ).saveProfile(fullName: 'Max Patient', notes: 'Lokal');
    await LocalPrivacyRepository(db).setAiContextAllowed(true);
    final snapshot = await LocalProfileRepository(db).snapshot();
    expect(snapshot.hasProfile, isTrue);
    expect(snapshot.aiContextAllowed, isTrue);
    db.close();
  });
}
