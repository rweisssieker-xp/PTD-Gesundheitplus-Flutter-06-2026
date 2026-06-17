# Flutter Production Readiness

Date: 2026-06-17

## Verified locally on Windows

- `flutter doctor -v`: no issues after installing Android SDK command-line tools and accepting Android licenses.
- `dart format lib test`: clean.
- `flutter analyze`: no issues.
- `flutter test`: 46 tests passed.
- `flutter build apk --debug`: built successfully.
- `flutter build apk --release`: built successfully with local release keystore.
- `flutter build appbundle --release`: built successfully with local release keystore.

## Current Android artifacts

- Debug APK: `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`
- Release APK: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- Release AAB: `flutter_app/build/app/outputs/bundle/release/app-release.aab`

## Android release signing

Android release signing is configured through ignored local files:

- `flutter_app/android/key.properties`
- `flutter_app/android/upload-keystore.jks`

The checked-in Gradle configuration reads `key.properties` and does not commit signing secrets.
Keep a secure backup of the generated upload keystore and passwords before publishing.

## Feature parity status

The authoritative feature matrix is `docs/superpowers/tracking/flutter-feature-matrix.md`.
All rows are implemented and the router no longer uses placeholder feature shells.

## Remaining production gates

1. iOS build verification requires macOS with Xcode. The Windows Flutter toolchain in this workspace does not expose an iOS build subcommand.
2. App Store and Play Store release metadata, screenshots, privacy labels, and final store account configuration still need to be completed outside the codebase.

## iOS verification commands on macOS

Run these from `flutter_app` on a Mac with Xcode configured:

```powershell
flutter doctor -v
flutter analyze
flutter test
flutter build ios --release
```

For App Store distribution, open `ios/Runner.xcworkspace` in Xcode, configure the bundle identifier, team, signing certificates, and archive the app.
