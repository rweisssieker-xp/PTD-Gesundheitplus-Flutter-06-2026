import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/privacy/data/local_privacy_repository.dart';

void main() {
  test('stores AI context consent locally', () async {
    final db = AppDatabase.memory();
    final repo = LocalPrivacyRepository(db);
    expect((await repo.snapshot()).aiContextAllowed, isFalse);
    await repo.setAiContextAllowed(true);
    expect((await repo.snapshot()).aiContextAllowed, isTrue);
    await repo.setAiContextAllowed(false);
    expect((await repo.snapshot()).aiContextAllowed, isFalse);
    db.close();
  });

  test('clears all local data tables', () async {
    final db = AppDatabase.memory();
    final repo = LocalPrivacyRepository(db);
    db.execute('''
      INSERT INTO health_passes (
        id, pass_type, title, serial_number, created_at, updated_at
      )
      VALUES ('pass-1', 'Herzschrittmacher', 'Schrittmacherpass', 'SN-1', 'now', 'now')
    ''');
    db.execute('''
      INSERT INTO medications (
        id, name, active, reminder_times_json, created_at, updated_at
      )
      VALUES ('med-1', 'ASS', 1, '[]', 'now', 'now')
    ''');
    await repo.setAiContextAllowed(true);
    expect((await repo.snapshot()).totalRows, greaterThan(0));

    await repo.clearAllLocalData();

    final snapshot = await repo.snapshot();
    expect(snapshot.totalRows, 0);
    expect(snapshot.aiContextAllowed, isFalse);
    db.close();
  });

  test('clears locally stored document files before deleting rows', () async {
    final db = AppDatabase.memory();
    final temp = await Directory.systemTemp.createTemp('gp_privacy_clear_test');
    final file = File('${temp.path}/document.txt')..writeAsStringSync('scan');
    db.execute(
      '''
      INSERT INTO health_documents (
        id, title, category, local_path, captured_at, created_at, updated_at
      )
      VALUES ('doc-1', 'Scan', 'Befund', ?, 'now', 'now', 'now')
      ''',
      [file.path],
    );
    expect(file.existsSync(), isTrue);

    await LocalPrivacyRepository(db).clearAllLocalData();

    expect(file.existsSync(), isFalse);
    expect(
      db
          .select('SELECT COUNT(*) AS count FROM health_documents')
          .single['count'],
      0,
    );
    db.close();
    temp.deleteSync(recursive: true);
  });
}
