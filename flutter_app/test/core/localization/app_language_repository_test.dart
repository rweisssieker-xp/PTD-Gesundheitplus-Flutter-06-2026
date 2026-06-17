import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/localization/app_language.dart';
import 'package:gesundheitplus/src/core/localization/app_language_repository.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';

void main() {
  test('stores language preference locally', () async {
    final db = AppDatabase.memory();
    final repo = AppLanguageRepository(db);

    expect(await repo.read(), AppLanguage.de);

    await repo.save(AppLanguage.tr);
    expect(await repo.read(), AppLanguage.tr);

    await repo.save(AppLanguage.ar);
    expect(await repo.read(), AppLanguage.ar);

    db.close();
  });
}
