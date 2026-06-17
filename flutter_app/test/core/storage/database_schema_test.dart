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
        'appointments',
        'allergies',
        'emergency_contacts',
        'notifications',
        'consent_settings',
      ]),
    );
    db.close();
  });
}
