import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class DatabaseKeyStore {
  Future<String> readOrCreateKey();
}

class SecureDatabaseKeyStore implements DatabaseKeyStore {
  SecureDatabaseKeyStore({FlutterSecureStorage? storage, Random? random})
    : _storage = storage ?? const FlutterSecureStorage(),
      _random = random ?? Random.secure();

  static const _databaseKey = 'sqlite_database_key_v1';

  final FlutterSecureStorage _storage;
  final Random _random;

  @override
  Future<String> readOrCreateKey() async {
    final existing = await _storage.read(key: _databaseKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final key = base64UrlEncode(bytes);
    await _storage.write(key: _databaseKey, value: key);
    return key;
  }
}

class FixedDatabaseKeyStore implements DatabaseKeyStore {
  const FixedDatabaseKeyStore(this.key);

  final String key;

  @override
  Future<String> readOrCreateKey() async => key;
}
