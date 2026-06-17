import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest declares package visibility for handoff schemes', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    for (final scheme in ['tel', 'sms', 'smsto', 'whatsapp', 'tg']) {
      expect(manifest, contains('android:scheme="$scheme"'));
    }
  });

  test('Android release manifest allows optional online AI responder', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:name="android.permission.INTERNET"'));
  });

  test('iOS Info.plist declares third-party handoff query schemes', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(plist, contains('<key>LSApplicationQueriesSchemes</key>'));
    expect(plist, contains('<string>whatsapp</string>'));
    expect(plist, contains('<string>tg</string>'));
  });
}
