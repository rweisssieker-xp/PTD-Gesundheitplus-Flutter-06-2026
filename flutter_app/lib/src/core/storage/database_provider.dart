import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'database_key_store.dart';

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final key = await SecureDatabaseKeyStore().readOrCreateKey();
  final db = AppDatabase.local(
    p.join(dir.path, 'gesundheit_plus_encrypted.sqlite'),
    encryptionKey: key,
  );
  ref.onDispose(db.close);
  return db;
});
