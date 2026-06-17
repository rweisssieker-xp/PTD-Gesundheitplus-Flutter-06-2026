# Gesundheit Plus Flutter App

Native, local-first Flutter migration of the Gesundheit Plus PWA for Android and iOS.

The app stores health data on the device, uses SQLCipher for the local SQLite database, and exposes native handoff features for notifications, documents, emergency contact actions, contacts import, location-assisted emergency messages, biometric/PIN unlock, and file sharing.

## Requirements

- Flutter SDK with Android toolchain configured
- Android SDK licenses accepted
- For iOS builds: macOS with Xcode and a configured Apple Developer team
- Local release signing files for Android release artifacts:
  - `android/key.properties`
  - `android/upload-keystore.jks`

Use `android/key.properties.example` as the template. Do not commit signing secrets.

## Common Commands

Run from this directory:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

iOS release verification must be run on macOS:

```powershell
flutter analyze
flutter test
flutter build ios --release
```

## Local-First Behavior

- First launch asks for the storage mode and opens the dashboard only after local-device storage is selected.
- Structured records are stored in encrypted local SQLite.
- Documents are copied into app-controlled storage.
- Privacy wipe deletes local document files before deleting database rows.
- The AI coach is local by default. Optional online responder integration is consent-gated and must fail visibly without changing health records.
- Native reminders use local notifications with inexact scheduling; the app does not require exact-alarm special access.

## Platform Notes

Android:

- Package id: `de.gesundheitplus.gesundheitplus`
- App label: `Gesundheit Plus`
- Release signing is configured in `android/app/build.gradle.kts`.
- Impeller is disabled in the Android embedding for the currently verified emulator path because the Flutter UI hierarchy was present while the emulator hardware screenshot surface remained black.

iOS:

- Bundle identifier: `de.gesundheitplus.gesundheitplus`
- Display name: `Gesundheit Plus`
- Permission usage strings are declared in `ios/Runner/Info.plist`.
- Final archive/signing must be completed in Xcode.

## Documentation

- Feature parity matrix: `../docs/superpowers/tracking/flutter-feature-matrix.md`
- Production readiness log: `../docs/flutter-production-readiness.md`
- Store readiness notes: `../docs/store-release-readiness.md`
