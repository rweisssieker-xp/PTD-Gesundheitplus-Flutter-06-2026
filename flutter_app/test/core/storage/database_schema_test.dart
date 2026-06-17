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
        'preventive_care_items',
        'health_documents',
        'emergency_contacts',
        'notifications',
        'consent_settings',
        'ai_coach_messages',
        'communication_preferences',
        'family_members',
        'family_check_ins',
        'dementia_logs',
      ]),
    );
    db.close();
  });
}
