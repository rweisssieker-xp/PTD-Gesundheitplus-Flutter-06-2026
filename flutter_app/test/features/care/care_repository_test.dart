import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/care/data/care_repository.dart';

void main() {
  test('stores family members and check-ins locally', () async {
    final db = AppDatabase.memory();
    final repo = CareRepository(db);
    await repo.addFamilyMember(
      name: 'Anna',
      relationship: 'Tochter',
      phone: '+49123',
    );
    final members = await repo.listFamilyMembers();
    expect(members.single.name, 'Anna');
    await repo.addCheckIn(
      memberId: members.single.id,
      memberName: members.single.name,
      status: 'safe',
      note: 'Alles ok',
      locationText: '52.5200, 13.4050',
      checkedAt: DateTime(2026, 6, 17),
    );
    final checkIn = (await repo.listCheckIns()).single;
    expect(checkIn.status, 'safe');
    expect(checkIn.note, 'Alles ok');
    expect(checkIn.locationText, '52.5200, 13.4050');
    db.close();
  });

  test('stores dementia support logs locally', () async {
    final db = AppDatabase.memory();
    final repo = CareRepository(db);
    await repo.addDementiaLog(
      type: 'Trinken',
      value: 'Wasser',
      loggedAt: DateTime(2026, 6, 17),
    );
    final logs = await repo.listDementiaLogs();
    expect(logs.single.type, 'Trinken');
    expect(logs.single.value, 'Wasser');
    db.close();
  });
}
