import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'app_database.dart';
import 'database_key_store.dart';

var _sqlCipherLoaderConfigured = false;

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  _configureSqlCipherLoader();
  final dir = await getApplicationDocumentsDirectory();
  final key = await SecureDatabaseKeyStore().readOrCreateKey();
  final db = AppDatabase.local(
    p.join(dir.path, 'gesundheit_plus_encrypted.sqlite'),
    encryptionKey: key,
  );
  ref.onDispose(db.close);
  return db;
});

void _configureSqlCipherLoader() {
  if (_sqlCipherLoaderConfigured) return;
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  _sqlCipherLoaderConfigured = true;
}
