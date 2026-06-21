import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GitHub CI runs Flutter quality gates for main', () {
    final workflow = File(
      '../.github/workflows/flutter-ci.yml',
    ).readAsStringSync();

    expect(workflow, contains('pull_request:'));
    expect(workflow, contains('branches:'));
    expect(workflow, contains('- main'));
    expect(workflow, contains('uses: actions/checkout@v4'));
    expect(workflow, contains('uses: actions/setup-java@v4'));
    expect(workflow, contains('java-version: "17"'));
    expect(workflow, contains('uses: subosito/flutter-action@v2'));
    expect(workflow, contains('working-directory: flutter_app'));
    expect(workflow, contains('run: flutter pub get'));
    expect(workflow, contains('run: flutter analyze'));
    expect(workflow, contains('run: flutter test'));
    expect(workflow, contains('run: flutter build apk --debug'));
    expect(workflow, contains('uses: actions/upload-artifact@v4'));
  });

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

  test('native transport security disallows cleartext traffic', () {
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();

    expect(androidManifest, contains('android:usesCleartextTraffic="false"'));
    expect(iosInfo, isNot(contains('<key>NSAppTransportSecurity</key>')));
    expect(iosInfo, isNot(contains('<key>NSAllowsArbitraryLoads</key>')));
  });

  test('Android release disables automatic health data backup', () {
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final extractionRules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();

    expect(androidManifest, contains('android:allowBackup="false"'));
    expect(androidManifest, contains('android:fullBackupContent="false"'));
    expect(
      androidManifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );

    for (final domain in ['database', 'file', 'sharedpref', 'external']) {
      expect(extractionRules, contains('<exclude domain="$domain" path="."'));
    }
  });

  test('Android startup keeps light shell and disables Impeller fallback', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final styles = File(
      'android/app/src/main/res/values/styles.xml',
    ).readAsStringSync();
    final nightStyles = File(
      'android/app/src/main/res/values-night/styles.xml',
    ).readAsStringSync();
    final launchBackground = File(
      'android/app/src/main/res/drawable/launch_background.xml',
    ).readAsStringSync();
    final launchBackgroundV21 = File(
      'android/app/src/main/res/drawable-v21/launch_background.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains('android:name="io.flutter.embedding.android.NormalTheme"'),
    );
    expect(manifest, contains('android:resource="@style/NormalTheme"'));
    expect(
      manifest,
      contains('android:name="io.flutter.embedding.android.EnableImpeller"'),
    );
    expect(manifest, contains('android:value="false"'));

    for (final xml in [styles, nightStyles]) {
      expect(xml, contains('Theme.Light.NoTitleBar'));
      expect(
        xml,
        contains(
          '<item name="android:windowBackground">@android:color/white</item>',
        ),
      );
    }
    expect(launchBackground, contains('@android:color/white'));
    expect(launchBackgroundV21, contains('@android:color/white'));
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

  test('iOS release config uses Flutter versioning and bundle identity', () {
    final iosProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(
      iosProject,
      contains('PRODUCT_BUNDLE_IDENTIFIER = de.gesundheitplus.gesundheitplus'),
    );
    expect(
      iosProject,
      contains('CURRENT_PROJECT_VERSION = "\$(FLUTTER_BUILD_NUMBER)"'),
    );
    expect(iosProject, contains('INFOPLIST_FILE = Runner/Info.plist'));
    expect(iosProject, contains('VERSIONING_SYSTEM = "apple-generic"'));
    expect(iosInfo, contains('<key>CFBundleShortVersionString</key>'));
    expect(iosInfo, contains('<string>\$(FLUTTER_BUILD_NAME)</string>'));
    expect(iosInfo, contains('<key>CFBundleVersion</key>'));
    expect(iosInfo, contains('<string>\$(FLUTTER_BUILD_NUMBER)</string>'));
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

  test('native manifests avoid unused microphone and calendar permissions', () {
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();

    for (final permission in [
      'android.permission.RECORD_AUDIO',
      'android.permission.READ_CALENDAR',
      'android.permission.WRITE_CALENDAR',
    ]) {
      expect(androidManifest, isNot(contains(permission)));
    }

    for (final key in [
      'NSMicrophoneUsageDescription',
      'NSCalendarsUsageDescription',
      'NSCalendarsFullAccessUsageDescription',
      'NSCalendarsWriteOnlyAccessUsageDescription',
    ]) {
      expect(iosInfo, isNot(contains(key)));
    }
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

  test('iOS privacy manifest declares no tracking and required reasons', () {
    final privacyManifest = File(
      'ios/Runner/PrivacyInfo.xcprivacy',
    ).readAsStringSync();

    expect(privacyManifest, contains('<key>NSPrivacyTracking</key>'));
    expect(privacyManifest, contains('<false/>'));
    expect(privacyManifest, contains('<key>NSPrivacyTrackingDomains</key>'));
    expect(privacyManifest, contains('<key>NSPrivacyCollectedDataTypes</key>'));
    expect(privacyManifest, contains('<array/>'));
    expect(privacyManifest, contains('<key>NSPrivacyAccessedAPITypes</key>'));
    expect(
      privacyManifest,
      contains('<string>NSPrivacyAccessedAPICategoryUserDefaults</string>'),
    );
    expect(privacyManifest, contains('<string>CA92.1</string>'));
    expect(
      privacyManifest,
      contains('<string>NSPrivacyAccessedAPICategoryFileTimestamp</string>'),
    );
    expect(privacyManifest, contains('<string>C617.1</string>'));
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

      for (final omittedPermissionClaim in [
        'Microphone: spoken-style input is entered as text',
        'Calendar read/write: appointments are exported',
      ]) {
        expect(readiness, contains(omittedPermissionClaim));
      }

      for (final dataSafetyClaim in [
        'No automatic backend sharing is implemented.',
        'Optional AI responder integration is not active by default',
        'Cloud-Sync is not implemented or selectable',
        'Twilio backend sending is not bundled',
        'Structured data is encrypted at rest with SQLCipher.',
        'Stored health document files are encrypted with AES-GCM',
        'Android automatic app backup is disabled',
        'in-app privacy and legal screen includes a medical disclaimer',
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
