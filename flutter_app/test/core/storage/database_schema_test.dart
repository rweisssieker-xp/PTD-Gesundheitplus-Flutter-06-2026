import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';

void main() {
  test('database exposes core medical tables', () {
    final db = AppDatabase.memory();
    expect(
      db.allTables.map((table) => table.actualTableName),
      containsAll([
        'local_profiles',
        'medications',
        'medication_logs',
        'medication_interaction_guidance',
        'medication_interaction_checks',
        'appointments',
        'healthcare_professionals',
        'medical_history_entries',
        'treatment_records',
        'allergies',
        'blood_pressure_logs',
        'weight_logs',
        'vaccinations',
        'health_passes',
        'preventive_care_items',
        'health_documents',
        'emergency_contacts',
        'notifications',
        'consent_settings',
        'app_preferences',
        'ai_coach_messages',
        'communication_preferences',
        'family_members',
        'family_check_ins',
        'dementia_logs',
      ]),
    );
    db.close();
  });

  test('allergies table includes PWA parity fields', () {
    final db = AppDatabase.memory();
    final columns = db
        .select('PRAGMA table_info(allergies)')
        .map((row) => row['name'])
        .toSet();
    expect(
      columns,
      containsAll([
        'substance',
        'category',
        'reaction',
        'severity',
        'diagnosed_at',
        'diagnosed_by',
        'notes',
      ]),
    );
    db.close();
  });

  test('family check-ins include location parity field', () {
    final db = AppDatabase.memory();
    final columns = db
        .select('PRAGMA table_info(family_check_ins)')
        .map((row) => row['name'])
        .toSet();
    expect(columns, containsAll(['location_text', 'next_checkin_due']));
    db.close();
  });

  test('notifications include visible state fields', () {
    final db = AppDatabase.memory();
    final columns = db
        .select('PRAGMA table_info(notifications)')
        .map((row) => row['name'])
        .toSet();
    expect(columns, containsAll(['status', 'status_detail']));
    db.close();
  });

  test('health documents include encrypted file metadata fields', () {
    final db = AppDatabase.memory();
    final columns = db
        .select('PRAGMA table_info(health_documents)')
        .map((row) => row['name'])
        .toSet();
    expect(
      columns,
      containsAll(['file_key', 'file_nonce', 'file_mac', 'encrypted']),
    );
    db.close();
  });

  test('health passes include PWA parity fields', () {
    final db = AppDatabase.memory();
    final columns = db
        .select('PRAGMA table_info(health_passes)')
        .map((row) => row['name'])
        .toSet();
    expect(
      columns,
      containsAll([
        'pass_type',
        'title',
        'implanted_at',
        'manufacturer',
        'model',
        'material',
        'serial_number',
        'notes',
      ]),
    );
    db.close();
  });

  test('blood pressure logs include PWA context field', () {
    final db = AppDatabase.memory();
    final columns = db
        .select('PRAGMA table_info(blood_pressure_logs)')
        .map((row) => row['name'])
        .toSet();
    expect(columns, contains('context'));
    db.close();
  });
}
