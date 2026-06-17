import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/security/app_lock_service.dart';

void main() {
  test('new app requires PIN setup', () async {
    final store = InMemorySecretStore();
    final service = AppLockService(store: store);
    expect(await service.hasPin(), isFalse);
  });

  test('stores and validates PIN hash', () async {
    final store = InMemorySecretStore();
    final service = AppLockService(store: store);
    await service.setPin('123456');
    expect(await service.hasPin(), isTrue);
    expect(await service.unlockWithPin('123456'), isTrue);
    expect(await service.unlockWithPin('000000'), isFalse);
  });

  test('rejects non six digit PIN', () async {
    final store = InMemorySecretStore();
    final service = AppLockService(store: store);
    expect(() => service.setPin('12345'), throwsArgumentError);
    expect(() => service.setPin('abcdef'), throwsArgumentError);
  });

  test('enables and uses biometrics when available', () async {
    final store = InMemorySecretStore();
    final biometrics = _FakeBiometrics(available: true, result: true);
    final service = AppLockService(
      store: store,
      biometricAuthenticator: biometrics,
    );
    await service.setBiometricEnabled(true);
    expect(await service.isBiometricEnabled(), isTrue);
    expect(await service.unlockWithBiometrics(), isTrue);
    expect(biometrics.authenticateCalls, 1);
  });

  test('rejects biometric enablement when unavailable', () async {
    final service = AppLockService(
      store: InMemorySecretStore(),
      biometricAuthenticator: _FakeBiometrics(available: false, result: false),
    );
    expect(() => service.setBiometricEnabled(true), throwsStateError);
    expect(await service.unlockWithBiometrics(), isFalse);
  });
}

class _FakeBiometrics implements BiometricAuthenticator {
  _FakeBiometrics({required this.available, required this.result});

  final bool available;
  final bool result;
  int authenticateCalls = 0;

  @override
  Future<bool> canAuthenticate() async => available;

  @override
  Future<bool> authenticate() async {
    authenticateCalls++;
    return result;
  }
}
