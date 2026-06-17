import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureStorageSecretStore implements SecretStore {
  SecureStorageSecretStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class InMemorySecretStore implements SecretStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

class AppLockService {
  AppLockService({required SecretStore store}) : _store = store;

  static const _pinHashKey = 'pin_hash';
  final SecretStore _store;

  Future<bool> hasPin() async => (await _store.read(_pinHashKey)) != null;

  Future<void> setPin(String pin) async {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(pin)) {
      throw ArgumentError.value(
        pin,
        'pin',
        'PIN must contain exactly 6 digits',
      );
    }
    await _store.write(_pinHashKey, _hash(pin));
  }

  Future<bool> unlockWithPin(String pin) async {
    final stored = await _store.read(_pinHashKey);
    return stored != null && stored == _hash(pin);
  }

  String _hash(String pin) =>
      sha256.convert(utf8.encode('gesundheit-plus:$pin')).toString();
}
