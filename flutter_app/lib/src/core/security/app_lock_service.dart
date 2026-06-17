import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

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

abstract class BiometricAuthenticator {
  Future<bool> canAuthenticate();
  Future<bool> authenticate();
}

class DeviceBiometricAuthenticator implements BiometricAuthenticator {
  DeviceBiometricAuthenticator({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> canAuthenticate() async {
    final supported = await _localAuthentication.isDeviceSupported();
    final canCheck = await _localAuthentication.canCheckBiometrics;
    return supported && canCheck;
  }

  @override
  Future<bool> authenticate() {
    return _localAuthentication.authenticate(
      localizedReason: 'Gesundheit Plus entsperren',
      options: const AuthenticationOptions(biometricOnly: true),
    );
  }
}

class DisabledBiometricAuthenticator implements BiometricAuthenticator {
  const DisabledBiometricAuthenticator();

  @override
  Future<bool> canAuthenticate() async => false;

  @override
  Future<bool> authenticate() async => false;
}

class AppLockService {
  AppLockService({
    required SecretStore store,
    BiometricAuthenticator? biometricAuthenticator,
  }) : _store = store,
       _biometricAuthenticator =
           biometricAuthenticator ?? DeviceBiometricAuthenticator();

  static const _pinHashKey = 'pin_hash';
  static const _biometricEnabledKey = 'biometric_enabled';
  final SecretStore _store;
  final BiometricAuthenticator _biometricAuthenticator;

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

  Future<bool> canUseBiometrics() => _biometricAuthenticator.canAuthenticate();

  Future<bool> isBiometricEnabled() async =>
      (await _store.read(_biometricEnabledKey)) == 'true';

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled && !await canUseBiometrics()) {
      throw StateError('Biometric authentication is not available');
    }
    await _store.write(_biometricEnabledKey, enabled ? 'true' : 'false');
  }

  Future<bool> unlockWithBiometrics() async {
    if (!await isBiometricEnabled()) return false;
    if (!await canUseBiometrics()) return false;
    return _biometricAuthenticator.authenticate();
  }

  String _hash(String pin) =>
      sha256.convert(utf8.encode('gesundheit-plus:$pin')).toString();
}
