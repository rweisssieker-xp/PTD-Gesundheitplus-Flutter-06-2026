import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/health_record/data/health_record_repository.dart';

void main() {
  test('stores and deletes anamnesis entries', () async {
    final db = AppDatabase.memory();
    final repo = HealthRecordRepository(db);
    await repo.addHistoryEntry(category: 'Vorerkrankung', title: 'Asthma');
    final created = await repo.listHistoryEntries();
    expect(created.single.title, 'Asthma');
    await repo.deleteHistoryEntry(created.single.id);
    expect(await repo.listHistoryEntries(), isEmpty);
    db.close();
  });

  test('stores and sorts treatment records', () async {
    final db = AppDatabase.memory();
    final repo = HealthRecordRepository(db);
    await repo.addTreatment(
      title: 'Kontrolle',
      treatedAt: DateTime(2026, 1, 1),
    );
    await repo.addTreatment(
      title: 'Operation',
      treatedAt: DateTime(2026, 6, 1),
    );
    final records = await repo.listTreatments();
    expect(records.first.title, 'Operation');
    db.close();
  });
}
