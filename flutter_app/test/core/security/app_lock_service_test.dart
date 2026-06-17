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
}
