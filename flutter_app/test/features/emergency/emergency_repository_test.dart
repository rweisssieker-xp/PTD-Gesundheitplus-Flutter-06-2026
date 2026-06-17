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

  test('builds local emergency profile from stored local records', () async {
    final db = AppDatabase.memory();
    final repo = EmergencyRepository(db);
    db.execute('''
      INSERT INTO local_profiles (
        id, full_name, date_of_birth, notes, created_at, updated_at
      )
      VALUES ('default', 'Erika Muster', NULL, 'Diabetes Typ 2', 'now', 'now')
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
    await repo.addContact(name: 'Max Kontakt', phone: '112233');
    final profile = await repo.buildLocalProfile();
    expect(profile.fullName, 'Erika Muster');
    expect(profile.notes, 'Diabetes Typ 2');
    expect(profile.medications, contains('ASS'));
    expect(profile.allergies, contains('Penicillin (Schwer)'));
    expect(profile.diagnoses, contains('Asthma'));
    expect(profile.contacts.single.name, 'Max Kontakt');
    db.close();
  });
}
