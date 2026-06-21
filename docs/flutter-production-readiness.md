# Flutter Production Readiness

Date: 2026-06-21

## Verified locally on Windows

- `flutter doctor -v`: no issues after installing Android SDK command-line tools and accepting Android licenses.
- `dart format lib test`: clean.
- `flutter analyze`: no issues.
- `flutter test`: 162 tests passed.
- `flutter test integration_test/app_flow_test.dart`: Android integration flow passed on the local emulator, including first-run local storage selection and core feature route rendering.
- `flutter build apk --debug`: built successfully.
- `flutter build apk --release`: built successfully with local release keystore.
- `flutter build appbundle --release`: built successfully with local release keystore.

## Current Android artifacts

- Debug APK: `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`
- Release APK: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- Release AAB: `flutter_app/build/app/outputs/bundle/release/app-release.aab`
- Store-facing metadata and privacy drafts: `docs/store-release-readiness.md`

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
Android dark-mode startup now keeps the native launch/normal window background light so the app does not fall back to a black shell before Flutter paints.
Android embedding disables Impeller explicitly for this emulator-tested build path because the UI hierarchy was present while the hardware screenshot surface stayed black on the local emulator.

## Local data protection

- Structured health data is stored in a SQLCipher-backed local SQLite database.
- First launch shows a PWA-parity storage choice adapted for the native local-only app; selecting local persists the local-device mode on-device before opening the dashboard, while Cloud-Sync is visibly unavailable rather than selectable.
- Onboarding saves the local profile, PIN/biometric preference, AI consent, and requests native notification permission for local reminders with a visible recovery hint if permission is not granted.
- The database encryption key is generated on-device and stored through `flutter_secure_storage`, backed by iOS Keychain / Android Keystore.
- App access is protected by local PIN and optional device biometric unlock where supported.
- The app-lock bootstrap shows a visible light loading state and times out stalled secure-storage reads before opening the local shell.
- Document files copied into app storage are encrypted with AES-GCM before being stored; the file encryption metadata is held in the SQLCipher database. Stored document files are removed during the privacy data wipe before their metadata rows are deleted.
- Medication, appointment, preventive-care, and dementia-support reminders are scheduled as native local notifications on-device.
- Medications can be drafted from spoken-style German text using a deterministic on-device parser for medication name, dosage, frequency, prescribing doctor, reason, and reminder times.
- Medication creation through the native editor is covered end to end at widget level, including persisted reminder times shown back in the local medication list.
- Medication daily-plan intake can be confirmed from spoken-style German text on-device and stores the local `confirmedByVoice` audit flag.
- Medication interaction checker consent blocking and high-risk local rule results are covered at widget level and persisted on-device.
- The notification center shows system notification permission state, links blocked users to app settings, and surfaces per-notification states for active, permission-missing, system-blocked, needs-reschedule, and inactive reminders.
- Document scanning checks native camera/gallery permissions before opening the picker, links blocked users to app settings, and is covered through the successful local gallery-save contract; repository tests verify encrypted document storage and readback.
- The dashboard runs local proactive health checks on startup and writes deduplicated on-device alerts for medication refills, high-risk interaction checks, missing/unverified emergency contacts, and incomplete local emergency profile data.
- The iOS bundle display name is set to `Gesundheit Plus`.
- Android includes Gesundheit-Plus launcher icons for legacy and adaptive/round launcher surfaces.
- The iOS Runner target includes `PrivacyInfo.xcprivacy` with no tracking declaration and initial Required Reason API entries for app preferences and file metadata access.
- The PWA language switcher is backed by a local on-device preference and translates the native dashboard entry points for German, English, Turkish, Arabic, and Ukrainian.
- Emergency contacts expose native phone, SMS, WhatsApp, Telegram, system share, and current-location SMS handoff actions from the emergency profile and offline emergency views with visible failure messages when a target app is unavailable.
- Emergency contact setup creation, verification, and deletion are covered at widget level against local storage.
- The offline emergency QR copy action is covered at widget level and validates that the copied JSON payload contains local profile, medication, allergy, diagnosis, and emergency contact records.
- Telegram setup mirrors the PWA guided flow with bot launch, `/start`, `/mychatid`, local connect/disconnect, persisted chat target, and native Telegram test handoff without backend secrets.
- SMS/WhatsApp setup replaces Twilio backend sending with local native handoffs and keeps the PWA debug posture through E.164 phone preview, generated URI, visible success state, and visible failure diagnostics.
- Android release builds include network permission for the optional configured online AI responder; local health record features remain on-device and work without backend access.
- Emergency contacts can be imported from the device address book after explicit contact permission and remain stored locally.
- Local health-record JSON export and appointment `.ics` export show visible recovery messages when local file creation or native sharing fails.
- Local health-record JSON export is covered at widget level for the success path, including generated JSON content and native share handoff callback.
- Healthcare professionals expose a local Facharzt search with on-device provider suggestions and direct local add, replacing the PWA internet/LLM doctor search with a local-only workflow.
- Healthcare professionals can be drafted from spoken-style German text using a deterministic on-device parser for name, specialty, address, phone, and email.
- Allergies expose a local medication conflict check that compares active medications with medication allergies and known local substance-class rules without sending data off-device.
- Allergy creation, edit, severe warning display, and deletion are covered at widget level against local storage.
- Allergies can be drafted from spoken-style German text using a deterministic on-device parser for allergen, category, severity, and reaction.
- Preventive care exposes local age-based recommendations for due vaccinations and screenings, and can turn recommendations into local reminder-backed Vorsorge items.
- Preventive care manual creation and completion are covered at widget level against local reminder storage.
- Vaccination creation through the native editor is covered at widget level, including persisted booster due metadata in local storage.
- Anamnesis entries can be encoded into an offline-readable local QR payload for physician handoff.
- Treatment history creation, listing, visible read-aloud controls, and deletion are covered at widget level against local storage.
- Blood pressure and weight entry flows are covered at widget level, including persisted local measurements and local BMI calculation.
- Appointments can be exported on-device as `.ics` calendar files for native calendar app handoff.
- Appointments can be drafted from spoken-style German text using a deterministic on-device parser for doctor, date, time, reason, specialty, and location.
- Appointment creation through the native editor is covered end to end at widget level, including persisted date/time and local reminder state shown back in the appointment list.
- Family-circle check-ins store local safety status, optional notes, and optional current-device location text on-device.
- Anamnesis, allergies, treatment history, healthcare professionals, appointments, medication, and vaccination screens expose native text-to-speech read-aloud summaries.
- Scanned documents expose local rule-based medical insights, urgency labels, recognized medical areas, and suggested actions without sending document data off-device.
- The AI coach remains local by default, labels local-only answers, builds consent-gated bounded local context only after explicit consent, and stores a visible recovery answer when an optional configured online responder fails without changing health records.
- AI consent and revoke are covered at widget level: the coach answers after context consent, privacy settings can revoke the consent, and the next AI question is visibly blocked from health context.
- Local data deletion is covered through the privacy screen confirmation flow and verifies that local health rows are removed after the user confirms deletion.
- Optional online AI can be enabled at build time with `--dart-define=GESUNDHEIT_PLUS_AI_ENDPOINT=https://...`; when omitted, the AI coach stays local-only.

## Remaining production gates

1. iOS build verification and generated Privacy Report review require macOS with Xcode. The Windows Flutter toolchain in this workspace does not expose an iOS build subcommand.
2. App Store and Play Store release metadata, screenshots, privacy labels, and final store account configuration still need to be completed in the store consoles. Draft copy and privacy answers are tracked in `docs/store-release-readiness.md`.
3. If online AI is enabled for a release build, configure `GESUNDHEIT_PLUS_AI_ENDPOINT` through CI or store build settings and re-run the AI consent/failure tests against the selected endpoint contract.

## iOS verification commands on macOS

Run these from `flutter_app` on a Mac with Xcode configured:

```powershell
flutter doctor -v
flutter analyze
flutter test
flutter build ios --release
```

For App Store distribution, open `ios/Runner.xcworkspace` in Xcode, configure the bundle identifier, team, signing certificates, and archive the app.
