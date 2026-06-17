import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/device_contact.dart';
import '../domain/emergency_profile.dart';

class EmergencyRepository {
  EmergencyRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> addContact({
    required String name,
    String? relationship,
    String? phone,
    String? email,
    String? messenger,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO emergency_contacts (
        id, name, relationship, phone, email, messenger, verified, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?)
      ''',
      [_uuid.v4(), name, relationship, phone, email, messenger, now, now],
    );
  }

  Future<int> importDeviceContacts(List<DeviceContact> contacts) async {
    var imported = 0;
    for (final contact in contacts) {
      final name = contact.name.trim();
      final phone = normalizeGermanPhoneNumber(contact.phone);
      if (name.isEmpty || phone.isEmpty) continue;
      await addContact(
        name: name,
        relationship: 'Sonstige',
        phone: phone,
        messenger: null,
      );
      imported++;
    }
    return imported;
  }

  Future<List<EmergencyContact>> listContacts() async {
    final rows = _db.select('''
      SELECT id, name, relationship, phone, email, messenger, verified
      FROM emergency_contacts
      ORDER BY name ASC
      ''');
    return rows
        .map(
          (row) => EmergencyContact(
            id: row['id'] as String,
            name: row['name'] as String,
            relationship: row['relationship'] as String?,
            phone: row['phone'] as String?,
            email: row['email'] as String?,
            messenger: row['messenger'] as String?,
            verified: row['verified'] == 1,
          ),
        )
        .toList();
  }

  Future<void> verifyContact(String id) async {
    _db.execute(
      'UPDATE emergency_contacts SET verified = 1, updated_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> deleteContact(String id) async {
    _db.execute('DELETE FROM emergency_contacts WHERE id = ?', [id]);
  }

  Future<EmergencyProfile> buildLocalProfile() async {
    final profileRows = _db.select('''
      SELECT full_name, notes
      FROM local_profiles
      WHERE id = 'default'
      LIMIT 1
      ''');
    final medicationRows = _db.select(
      "SELECT name FROM medications WHERE active = 1 ORDER BY name ASC LIMIT 20",
    );
    final allergyRows = _db.select('''
      SELECT substance, severity
      FROM allergies
      ORDER BY
        CASE severity
          WHEN 'Lebensbedrohlich' THEN 0
          WHEN 'Schwer' THEN 1
          WHEN 'Mittel' THEN 2
          WHEN 'Leicht' THEN 3
          ELSE 4
        END,
        substance ASC
      LIMIT 20
      ''');
    final diagnosisRows = _db.select('''
      SELECT title
      FROM medical_history_entries
      WHERE active = 1
      ORDER BY title ASC
      LIMIT 20
      ''');
    final contacts = await listContacts();
    final profileRow = profileRows.isEmpty ? null : profileRows.first;
    final fullName = (profileRow?['full_name'] as String?)?.trim();
    return EmergencyProfile(
      fullName: fullName == null || fullName.isEmpty ? 'Patient' : fullName,
      notes:
          (profileRow?['notes'] as String?) ??
          'Lokal auf diesem Gerät gespeichert',
      medications: medicationRows.map((row) => row['name'] as String).toList(),
      allergies: allergyRows.map((row) {
        final substance = row['substance'] as String;
        final severity = row['severity'] as String?;
        return severity == null || severity.isEmpty
            ? substance
            : '$substance ($severity)';
      }).toList(),
      diagnoses: diagnosisRows.map((row) => row['title'] as String).toList(),
      contacts: contacts
          .where(
            (contact) => contact.phone != null && contact.phone!.isNotEmpty,
          )
          .map(
            (contact) => EmergencyContactSummary(
              name: contact.name,
              phone: contact.phone!,
            ),
          )
          .toList(),
    );
  }
}

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    this.relationship,
    this.phone,
    this.email,
    this.messenger,
    required this.verified,
  });

  final String id;
  final String name;
  final String? relationship;
  final String? phone;
  final String? email;
  final String? messenger;
  final bool verified;
}
