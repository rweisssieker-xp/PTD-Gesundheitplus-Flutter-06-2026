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
        'appointments',
        'healthcare_professionals',
        'allergies',
        'blood_pressure_logs',
        'weight_logs',
        'vaccinations',
        'preventive_care_items',
        'emergency_contacts',
        'notifications',
        'consent_settings',
      ]),
    );
    db.close();
  });
}
