import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/emergency/data/emergency_repository.dart';
import 'package:gesundheitplus/src/features/emergency/domain/device_contact.dart';

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
    'imports device contacts as unverified local emergency contacts',
    () async {
      final db = AppDatabase.memory();
      final repo = EmergencyRepository(db);

      final imported = await repo.importDeviceContacts(const [
        DeviceContact(
          id: 'device-1',
          name: 'Bernd Beispiel',
          phone: '0176 123456',
        ),
        DeviceContact(id: 'device-2', name: '  ', phone: '+491700000'),
      ]);

      final contacts = await repo.listContacts();
      expect(imported, 1);
      expect(contacts.single.name, 'Bernd Beispiel');
      expect(contacts.single.relationship, 'Sonstige');
      expect(contacts.single.phone, '+49176123456');
      expect(contacts.single.verified, isFalse);
      db.close();
    },
  );

  test('normalizes german phone numbers from address book values', () {
    expect(normalizeGermanPhoneNumber('0176 123 456'), '+49176123456');
    expect(normalizeGermanPhoneNumber('0049 30 123'), '+4930123');
    expect(normalizeGermanPhoneNumber('+49 30 123'), '+4930123');
  });

  test('builds local emergency profile from stored local records', () async {
    final db = AppDatabase.memory();
    final repo = EmergencyRepository(db);
    db.execute('''
      INSERT INTO local_profiles (
        id, full_name, date_of_birth, notes, created_at, updated_at
      )
      VALUES ('default', 'Erika Muster', '1970-01-02T00:00:00.000', 'Diabetes Typ 2', 'now', 'now')
      ''');
    db.execute('''
      INSERT INTO medications (
        id, name, dosage, frequency, active, reminder_times_json, created_at, updated_at
      )
      VALUES ('med-1', 'ASS', '100mg', 'taeglich', 1, '[]', 'now', 'now')
      ''');
    db.execute('''
      INSERT INTO allergies (
        id, substance, category, reaction, severity, created_at, updated_at
      )
      VALUES ('allergy-1', 'Penicillin', 'Medikament', 'Atemnot', 'Schwer', 'now', 'now')
      ''');
    db.execute('''
      INSERT INTO medical_history_entries (
        id, category, title, details, active, created_at, updated_at
      )
      VALUES ('history-1', 'Diagnose', 'Asthma', NULL, 1, 'now', 'now')
      ''');
    db.execute('''
      INSERT INTO health_passes (
        id, pass_type, title, implanted_at, manufacturer, model, serial_number, created_at, updated_at
      )
      VALUES (
        'pass-1', 'Implantatpass', 'Knieprothese',
        '2024-05-01T00:00:00.000', 'MediCorp', 'K-42', 'SN123', 'now', 'now'
      )
      ''');
    await repo.addContact(
      name: 'Max Kontakt',
      phone: '112233',
      messenger: '@maxhilfe',
    );
    final profile = await repo.buildLocalProfile();
    expect(profile.fullName, 'Erika Muster');
    expect(profile.dateOfBirth, DateTime(1970, 1, 2));
    expect(profile.notes, 'Diabetes Typ 2');
    expect(profile.medications, contains('ASS (100mg, taeglich)'));
    expect(profile.allergies, contains('Penicillin (Schwer, Atemnot)'));
    expect(profile.diagnoses, contains('Asthma'));
    expect(
      profile.healthPasses,
      contains(
        'Implantatpass: Knieprothese (01.05.2024, MediCorp, K-42, SN SN123)',
      ),
    );
    expect(profile.criticalWarnings, contains('Allergie: Penicillin (Schwer)'));
    expect(profile.criticalWarnings, contains('Diagnose beachten: Asthma'));
    expect(profile.immediateActions, contains('Bei akuter Gefahr 112 rufen'));
    expect(profile.contacts.single.name, 'Max Kontakt');
    expect(profile.contacts.single.messenger, '@maxhilfe');
    db.close();
  });
}
