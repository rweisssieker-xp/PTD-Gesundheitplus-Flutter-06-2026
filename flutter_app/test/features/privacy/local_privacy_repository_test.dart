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
}
