import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/communication/data/communication_preferences_repository.dart';

void main() {
  test('stores communication handoff preferences locally', () async {
    final db = AppDatabase.memory();
    final repo = CommunicationPreferencesRepository(db);
    expect((await repo.get('sms')).enabled, isFalse);
    await repo.save(
      channel: 'sms',
      enabled: true,
      displayName: 'Notfall SMS',
      targetValue: '+491234',
    );
    final pref = await repo.get('sms');
    expect(pref.enabled, isTrue);
    expect(pref.targetValue, '+491234');
    db.close();
  });
}
