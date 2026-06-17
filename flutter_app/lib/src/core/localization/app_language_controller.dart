import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/database_provider.dart';
import 'app_language.dart';
import 'app_language_repository.dart';

final appLanguageControllerProvider =
    AsyncNotifierProvider<AppLanguageController, AppLanguage>(
      AppLanguageController.new,
    );

class AppLanguageController extends AsyncNotifier<AppLanguage> {
  @override
  Future<AppLanguage> build() async {
    final db = await ref.watch(appDatabaseProvider.future);
    return AppLanguageRepository(db).read();
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = AsyncData(language);
    final db = await ref.read(appDatabaseProvider.future);
    await AppLanguageRepository(db).save(language);
  }
}
