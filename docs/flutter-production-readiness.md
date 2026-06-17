# Flutter Production Readiness

Date: 2026-06-17

## Verified locally on Windows

- `flutter doctor -v`: no issues after installing Android SDK command-line tools and accepting Android licenses.
- `dart format lib test`: clean.
- `flutter analyze`: no issues.
- `flutter test`: 81 tests passed.
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
The native Flutter shell now mirrors the PWA layout pattern with the first-run storage-mode choice, a white header, red divider, local-mode badge, back/home controls on feature pages, and a constrained mobile content column.

## Local data protection

- Structured health data is stored in a SQLCipher-backed local SQLite database.
- First launch shows a PWA-parity storage choice; selecting local persists the local-device mode on-device before opening the dashboard.
- The database encryption key is generated on-device and stored through `flutter_secure_storage`, backed by iOS Keychain / Android Keystore.
- App access is protected by local PIN and optional device biometric unlock where supported.
- Document files copied into app storage are removed during the privacy data wipe before their metadata rows are deleted.
- Medication, appointment, preventive-care, and dementia-support reminders are scheduled as native local notifications on-device.
- Medications can be drafted from spoken-style German text using a deterministic on-device parser for medication name, dosage, frequency, prescribing doctor, reason, and reminder times.
- The notification center shows system notification permission state and links blocked users to app settings.
- The dashboard runs local proactive health checks on startup and writes deduplicated on-device alerts for medication refills, high-risk interaction checks, missing/unverified emergency contacts, and incomplete local emergency profile data.
- The iOS bundle display name is set to `Gesundheit Plus`.
- The PWA language switcher is backed by a local on-device preference and translates the native dashboard entry points for German, English, Turkish, Arabic, and Ukrainian.
- Emergency contacts expose native phone, SMS, and current-location SMS handoff actions from the emergency profile and offline emergency views.
- Emergency contacts can be imported from the device address book after explicit contact permission and remain stored locally.
- Healthcare professionals expose a local Facharzt search with on-device provider suggestions and direct local add, replacing the PWA internet/LLM doctor search with a local-only workflow.
- Allergies expose a local medication conflict check that compares active medications with medication allergies and known local substance-class rules without sending data off-device.
- Preventive care exposes local age-based recommendations for due vaccinations and screenings, and can turn recommendations into local reminder-backed Vorsorge items.
- Anamnesis entries can be encoded into an offline-readable local QR payload for physician handoff.
- Appointments can be exported on-device as `.ics` calendar files for native calendar app handoff.
- Appointments can be drafted from spoken-style German text using a deterministic on-device parser for doctor, date, time, reason, specialty, and location.
- Family-circle check-ins store local safety status, optional notes, and optional current-device location text on-device.
- Anamnesis, allergies, treatment history, healthcare professionals, appointments, medication, and vaccination screens expose native text-to-speech read-aloud summaries.
- Scanned documents expose local rule-based medical insights, urgency labels, recognized medical areas, and suggested actions without sending document data off-device.

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
