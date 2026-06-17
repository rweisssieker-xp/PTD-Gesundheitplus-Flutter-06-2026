import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock_service.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService(
    store: SecureStorageSecretStore(),
    biometricAuthenticator: DeviceBiometricAuthenticator(),
  );
});
