import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/emergency/data/emergency_repository.dart';

void main() {
  test('stores and verifies emergency contacts', () async {
    final db = AppDatabase.memory();
    final repo = EmergencyRepository(db);
    await repo.addContact(
      name: 'Anna Beispiel',
      relationship: 'Tochter',
      phone: '+491234',
    );
    final created = await repo.listContacts();
    expect(created.single.name, 'Anna Beispiel');
    expect(created.single.verified, isFalse);
    await repo.verifyContact(created.single.id);
    final verified = await repo.listContacts();
    expect(verified.single.verified, isTrue);
    db.close();
  });

  test(
    'builds local emergency profile from stored contacts and medication',
    () async {
      final db = AppDatabase.memory();
      final repo = EmergencyRepository(db);
      db.execute('''
      INSERT INTO medications (
        id, name, dosage, frequency, active, reminder_times_json, created_at, updated_at
      )
      VALUES ('med-1', 'ASS', '100mg', 'taeglich', 1, '[]', 'now', 'now')
      ''');
      await repo.addContact(name: 'Max Kontakt', phone: '112233');
      final profile = await repo.buildLocalProfile();
      expect(profile.medications, contains('ASS'));
      expect(profile.contacts.single.name, 'Max Kontakt');
      db.close();
    },
  );
}
