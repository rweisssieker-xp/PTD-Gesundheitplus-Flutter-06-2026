# Store Release Readiness

Date: 2026-06-18

This file captures store-facing metadata and privacy answers that can be derived from the current native Flutter implementation. It does not replace final review in the Apple Developer and Google Play Console accounts.

## App Identity

- App name: Gesundheit Plus
- Android package id: `de.gesundheitplus.gesundheitplus`
- iOS bundle id: `de.gesundheitplus.gesundheitplus`
- Category recommendation: Medical / Health & Fitness, depending on store policy review.
- Positioning: Local-first digital health record for medication, appointments, emergency profile, documents, preventive care, family check-ins, and consent-gated local AI support.

## Short Description Draft

Gesundheit Plus keeps your personal health record, medications, appointments, emergency information, and documents locally on your device.

## Long Description Draft

Gesundheit Plus is a local-first health companion for managing important medical information on your own device. The app helps you maintain medication plans, appointment records, allergies, treatment history, vaccination and preventive-care reminders, emergency contacts, emergency QR information, scanned health documents, family check-ins, and vital values.

Health data is stored locally in an encrypted SQLite database. Documents are encrypted and copied into app-controlled storage. Local notifications can remind you about medication, appointments, preventive care, and dementia-support tasks. Emergency features can hand off to native phone, SMS, WhatsApp, Telegram, system sharing, and current-location messages when you choose to use them.

The AI coach is local by default. Health context is only summarized after explicit consent, and optional online AI processing must fail with a visible recovery message without changing local health records.

Gesundheit Plus is not a medical diagnosis tool and does not replace professional medical advice.

## Permission Rationale

| Permission / Capability | Platform | Reason |
| --- | --- | --- |
| Camera | Android, iOS | Capture health document images locally. |
| Photos / media images | Android, iOS | Attach existing document images from the device library. |
| Contacts | Android, iOS | Import selected device contacts as local emergency contacts after consent. |
| Notifications | Android, iOS | Schedule local reminders for medication, appointments, preventive care, and support tasks. |
| Location while in use | Android, iOS | Add current-device location to emergency SMS and family check-ins when the user explicitly requests it. |
| Biometrics / Face ID | Android, iOS | Unlock the local health record with device biometric authentication when enabled by the user. |
| Phone/SMS/WhatsApp/Telegram/share handoff | Android, iOS | Let the user contact emergency contacts through native apps. |

## Google Play Data Safety Draft

Data collected by the app and stored locally on device:

- Personal info: profile name, date of birth, emergency contacts, family members.
- Health and fitness: medication, allergies, diagnoses/history, appointments, vitals, vaccinations, preventive care, health documents, emergency profile, AI coach message history.
- Location: only when the user requests current-location emergency/family features.
- Photos/files: document images selected or captured by the user.

Data sharing:

- No automatic backend sharing is implemented.
- User-initiated sharing can happen through native share sheets, phone, SMS, WhatsApp, Telegram, calendar file export, QR payloads, and exported health-record files.
- Optional AI responder integration is not active by default and is consent-gated.

Security:

- Structured data is encrypted at rest with SQLCipher.
- Stored health document files are encrypted with AES-GCM, with file metadata protected by the encrypted database.
- The database key is stored through platform secure storage.
- App access can be protected with PIN and optional biometrics.
- Local data wipe is available in privacy settings.

## Apple App Privacy Draft

The iOS target includes `flutter_app/ios/Runner/PrivacyInfo.xcprivacy` as a bundled Runner resource. It declares no tracking and includes initial Required Reason API entries for app preferences/UserDefaults and file metadata access. The final Xcode-generated Privacy Report must still be reviewed before App Store submission.

Potential data types handled by the app:

- Health and fitness data
- Contact info
- User content: documents/images and notes
- Location, only for explicit emergency/family check-in actions
- Identifiers are limited to local record ids generated on device

Tracking:

- No tracking is implemented in the current codebase.

Data linked to user:

- Health records, contacts, documents, and location can be associated with the local app user on the device, but are not sent to a backend by default.

## Screenshot Checklist

Required screenshots should be captured on real devices or reliable simulators/emulators after selecting local-device storage:

- Storage-mode first launch
- Home dashboard with emergency button, action grid, carousel, and footer
- Medication list and daily plan
- Appointments
- Emergency profile / offline emergency
- Document scan and scanned documents
- Privacy / local storage mode
- AI coach with local-only explanation

## External Gates

- iOS build/archive must be verified on macOS with Xcode.
- The Xcode generated Privacy Report must be checked against `PrivacyInfo.xcprivacy` and any third-party SDK manifests before submission.
- Final store privacy questionnaires must be completed in the store consoles.
- Final screenshots must be captured from real rendered devices because the current local Android emulator exposes the Flutter UI through accessibility hierarchy but returns a black hardware screenshot surface.
- Final medical disclaimer/legal text should be reviewed before public distribution.
