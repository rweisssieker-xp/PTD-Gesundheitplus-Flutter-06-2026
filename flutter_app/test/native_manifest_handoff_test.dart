import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native app identity is aligned for both stores', () {
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final iosProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();

    expect(androidManifest, contains('android:label="Gesundheit Plus"'));
    expect(
      iosProject,
      contains('PRODUCT_BUNDLE_IDENTIFIER = de.gesundheitplus.gesundheitplus'),
    );
    expect(iosInfo, contains('<string>Gesundheit Plus</string>'));
  });

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

  test('Android release Gradle config uses store identity and signing', () {
    final buildGradle = File('android/app/build.gradle.kts').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(
      buildGradle,
      contains('namespace = "de.gesundheitplus.gesundheitplus"'),
    );
    expect(
      buildGradle,
      contains('applicationId = "de.gesundheitplus.gesundheitplus"'),
    );
    expect(buildGradle, contains('versionCode = flutter.versionCode'));
    expect(buildGradle, contains('versionName = flutter.versionName'));
    expect(buildGradle, contains('create("release")'));
    expect(
      buildGradle,
      contains('signingConfig = signingConfigs.getByName("release")'),
    );
    expect(pubspec, contains('version: 1.0.0+1'));
  });

  test('iOS Info.plist declares third-party handoff query schemes', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(plist, contains('<key>LSApplicationQueriesSchemes</key>'));
    expect(plist, contains('<string>whatsapp</string>'));
    expect(plist, contains('<string>tg</string>'));
  });

  test('native manifests declare health feature permission rationale', () {
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();

    for (final permission in [
      'android.permission.CAMERA',
      'android.permission.READ_CONTACTS',
      'android.permission.POST_NOTIFICATIONS',
      'android.permission.USE_BIOMETRIC',
      'android.permission.ACCESS_COARSE_LOCATION',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.READ_MEDIA_IMAGES',
    ]) {
      expect(androidManifest, contains('android:name="$permission"'));
    }

    for (final key in [
      'NSCameraUsageDescription',
      'NSContactsUsageDescription',
      'NSPhotoLibraryUsageDescription',
      'NSFaceIDUsageDescription',
      'NSLocationWhenInUseUsageDescription',
    ]) {
      expect(iosInfo, contains('<key>$key</key>'));
    }

    expect(iosInfo, contains('lokal als Notfallkontakte importieren'));
    expect(iosInfo, contains('lokale Notfallfunktionen'));
  });

  test('release privacy and launcher icon artifacts are packaged', () {
    final iosProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final privacyManifest = File(
      'ios/Runner/PrivacyInfo.xcprivacy',
    ).readAsStringSync();

    expect(iosProject, contains('PrivacyInfo.xcprivacy in Resources'));
    expect(privacyManifest, contains('<key>NSPrivacyTracking</key>'));
    expect(privacyManifest, contains('<false/>'));
    expect(
      iosProject,
      contains('ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon'),
    );
    expect(
      File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
        'Icon-App-1024x1024@1x.png',
      ).existsSync(),
      isTrue,
    );

    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      expect(
        File(
          'android/app/src/main/res/mipmap-$density/ic_launcher.png',
        ).existsSync(),
        isTrue,
      );
    }
    expect(
      File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
      ).existsSync(),
      isTrue,
    );
  });

  test(
    'store readiness draft reflects the current local-only release posture',
    () {
      final readiness = File(
        '../docs/store-release-readiness.md',
      ).readAsStringSync();

      expect(readiness, contains('Date: 2026-06-21'));
      expect(readiness, contains('Cloud-Sync is not active'));
      expect(readiness, contains('local native SMS/WhatsApp handoffs'));
      expect(readiness, contains('adaptive and round launcher icons'));
      expect(readiness, contains('Release APK'));
      expect(readiness, contains('Release AAB'));

      for (final permissionReason in [
        'Capture health document images locally.',
        'Import selected device contacts as local emergency contacts',
        'Schedule local reminders',
        'Add current-device location to emergency SMS',
        'Unlock the local health record with device biometric authentication',
      ]) {
        expect(readiness, contains(permissionReason));
      }

      for (final dataSafetyClaim in [
        'No automatic backend sharing is implemented.',
        'Optional AI responder integration is not active by default',
        'Cloud-Sync is not implemented or selectable',
        'Twilio backend sending is not bundled',
        'Structured data is encrypted at rest with SQLCipher.',
        'Stored health document files are encrypted with AES-GCM',
      ]) {
        expect(readiness, contains(dataSafetyClaim));
      }

      for (final externalGate in [
        'iOS build/archive must be verified on macOS with Xcode.',
        'Final store privacy questionnaires must be completed',
        'Final screenshots must be captured from real rendered devices',
        'If online AI is enabled in a store build',
      ]) {
        expect(readiness, contains(externalGate));
      }
    },
  );
}
