# Flutter Native Migration Design

## Goal

Build a native Flutter app for iOS and Android from the existing `pwabase44` PWA. The target is feature parity with the current PWA, implemented as a local-first native app rather than a Base44 client.

The existing React/Base44 PWA remains the functional and visual reference. Flutter implementation should be a domain-driven rebuild, not a file-by-file port of React components.

## Confirmed Decisions

- Target platforms: iOS and Android.
- Migration target: feature parity with the current PWA.
- Backend: no Base44 runtime dependency in the Flutter app.
- Storage: all health data stored locally on the device.
- Authentication: no cloud account; app unlock through local PIN and biometric authentication.
- Existing PWA data import: not required.
- AI features: retained through online API calls.
- AI data access: after one-time consent, the app may include relevant local health data as context for AI requests.
- Notifications: full local native notifications for medication, appointments, preventive care, dementia support, hydration, meals, and related reminders.
- Emergency features: native QR code, emergency profile, location sharing, phone/SMS/WhatsApp/Telegram handoff where platform capabilities allow.
- Visual direction: faithful native. Keep the current Gesundheit Plus layout language, colors, and icon semantics while adapting interactions to Flutter and native platform expectations.

## Visual System

The Flutter app should preserve the recognizable PWA identity:

- App name: `Gesundheit Plus`.
- Header: white app header with strong red accent, matching the current medical/emergency emphasis.
- Background: light red-to-white or equivalent subtle health-record surface.
- Cards: white cards with restrained borders and shadows.
- Primary emergency action: prominent red emergency surface.
- Action tiles: colored gradient tiles for high-priority features such as AI coach, scan, daily plan, chat, family circle, interactions, and export.
- Feature icons: preserve the existing medical icon meanings. Flutter may use Material Symbols, Cupertino icons, or another consistent icon package, but every migrated feature must have a documented icon and color token.
- Layout: mobile-first, close to the current narrow app layout, with native Flutter spacing, touch targets, navigation transitions, dialogs, sheets, and permission prompts.

The goal is not an exact pixel clone. The app should feel like the same product rebuilt properly for iOS and Android.

## Architecture

Create a new Flutter app next to `pwabase44` under `flutter_app`. Keep the PWA in place as a reference during migration.

Use a domain-oriented structure:

- `app`: app startup, routing, theme, localization, global error boundaries, and top-level providers.
- `core`: encrypted local database, key management, PIN/biometric unlock, permission handling, local notification scheduling, logging, and AI consent state.
- `features`: domain modules such as medication, appointments, emergency, anamnesis, allergies, vaccination, documents, vital values, preventive care, dementia support, family circle, and AI coach.
- `shared_ui`: reusable Flutter widgets for headers, cards, action tiles, forms, empty states, icon/color tokens, and common loading/error states.
- `integrations`: optional online AI client and platform integrations for camera, contacts, calendar, location, phone, SMS, WhatsApp, Telegram, and sharing.

Base44 entities and integrations are not called from Flutter. Existing PWA pages, data fields, and flows are used to derive Flutter models and acceptance criteria.

## Local Data Model

Use encrypted local storage suitable for health data. The preferred design is:

- SQLite-based structured database through a Flutter persistence layer such as Drift.
- Database encryption or encrypted-at-rest strategy backed by a device-secure key.
- Key material stored in iOS Keychain and Android Keystore.
- PIN/biometric unlock controls access to the local encryption key.
- Document images and generated exports stored as encrypted local files, with metadata stored in the database.

Initial domain entities should cover the current local PWA export set and visible feature usage:

- Medication
- Appointment
- BloodPressureLog
- WeightLog
- Allergy
- Vaccination
- MedicalHistory
- EmergencyContact
- TreatmentHistory
- HealthcareProfessional
- ScannedDocument
- PreventiveCare
- HealthPass
- MedicationLog
- HydrationLog
- MealLog
- FamilyCheckIn
- DrugInteractionCheck
- Notification
- LocalProfile
- ConsentSettings

The implementation plan should refine field-level schemas by reading each PWA page and component that creates, updates, filters, or displays the entity.

## Feature Matrix

Feature parity is tracked through a migration matrix. Each PWA page maps to a Flutter feature area and gets a status of `not started`, `implemented`, `tested`, or `accepted`.

| PWA Area | Flutter Feature Group |
| --- | --- |
| Home, Gesundheits-Dashboard | Dashboard and navigation |
| Anamnese, Behandlungshistorie, Heilberufe | Health record |
| Medikation, Medikamenten-Tagesplan | Medication management |
| Medikations-Interaktionen, Wechselwirkungen-Checker | Medication safety and interactions |
| Blutdruck, Gewicht | Vital values |
| Impfpass, Vorsorge | Prevention and vaccination |
| Notfallprofil, Notfall-Einrichtung, Offline-Notfall | Emergency profile and offline emergency |
| Dokumenten-Scan, Gescannte-Dokumente | Documents and scanning |
| Daten-Export | Local export and sharing |
| Familien-Kreis | Family circle |
| Demenz-Unterstützung | Dementia support, hydration, meals, check-ins |
| KI-Gesundheitscoach | AI coach |
| Benachrichtigungen | Notification center |
| Datenschutz, Speicher-Modus | Privacy and local storage settings |
| Telegram-Setup, Twilio-Setup | Native communication settings or handoff flows |
| Onboarding | Local profile, consent, and security setup |

## Data Flows

### Local CRUD

Flutter UI reads and writes through repositories. Repositories own validation, database queries, sorting, and mapping between database rows and domain models. Screens do not talk directly to storage.

### Notifications

Reminder services observe local data and schedule native notifications. Medication schedules, appointments, preventive care, dementia support, hydration, meals, refill checks, and emergency-contact maintenance should be derived from local records.

Notification state must be visible to the user. Relevant states include active, permission missing, system blocked, needs reschedule, and inactive.

### AI

AI is an online integration with explicit privacy handling:

1. User grants one-time consent for AI context usage during onboarding or the first AI feature use.
2. The consent remains visible and revocable in privacy settings.
3. A context builder creates a bounded summary of relevant local health data.
4. The AI client sends the user prompt plus allowed context to the configured AI API.
5. Responses are displayed and, where useful, stored locally.

The app must distinguish local storage from online AI processing in UI copy. If the network is unavailable or the AI request fails, the feature shows a clear error and does not corrupt local records.

### Emergency

The emergency feature works without a backend:

- Emergency profile is generated from local records.
- QR code contains an offline-readable minimal emergency payload generated from local records, limited to emergency contacts, active medications, allergies, key diagnoses, vaccination/pass summary, and optional user-entered notes.
- Location sharing uses native permission flow and current device location.
- Contact actions use platform-supported handoff for phone, SMS, WhatsApp, Telegram, or system share sheet.

The design does not assume silent automatic message sending, because iOS/Android and third-party apps often restrict it.

## Error Handling

Medical and emergency workflows must not fail silently. Required error states:

- Local database unavailable or locked.
- PIN or biometric authentication failed.
- Encryption key unavailable.
- Permission denied for notifications, camera, location, contacts, calendar, or microphone.
- Messenger app not installed.
- Network unavailable for AI.
- AI timeout or rejected request.
- Notification scheduling failed or was blocked by the OS.
- Export or local file write failed.

Each error state should provide a recovery action where possible, such as opening settings, retrying, choosing another contact method, or continuing without the optional integration.

## Privacy And Security

The app is local-first and has no cloud account model.

- First launch sets up a local profile, PIN, optional biometric unlock, notification permissions, and AI consent.
- Health data is encrypted locally.
- No existing PWA data is imported.
- No cloud sync is added in this scope.
- Export requires explicit user action and creates a local file for user-controlled sharing.
- AI context sharing is enabled only after one-time consent and can be revoked.
- Privacy settings show local storage status, AI consent status, export controls, and data deletion controls.

## Testing Strategy

### Unit Tests

- Domain model validation.
- Repository CRUD behavior.
- Encryption/key unlock flows at the abstraction boundary.
- Reminder rule generation.
- Notification scheduling inputs.
- AI context builder and consent enforcement.
- Emergency profile generation.

### Widget Tests

- Onboarding and PIN setup.
- App lock and unlock.
- Dashboard navigation.
- Core forms for medication, appointment, allergies, vaccination, blood pressure, and weight.
- Consent dialogs and privacy settings.
- Empty states and permission-denied states.

### Integration Tests

- First-run setup with PIN and optional biometric path mocked.
- Add medication and schedule reminder.
- Add appointment and schedule reminder.
- Generate emergency profile and QR code.
- Trigger emergency contact handoff.
- Scan or attach a document.
- Export health record.
- Use AI feature after consent.
- Revoke AI consent and verify AI context is blocked.

## Scope Boundaries

In scope:

- New Flutter app structure.
- Feature-parity target with the current PWA.
- Local encrypted data model.
- PIN/biometric app protection.
- Native local notifications.
- Native emergency handoff features.
- Online AI features with consent.
- Faithful-native UI system.

Out of scope:

- Importing existing PWA data.
- Base44 backend dependency in Flutter.
- Cloud synchronization.
- Silent automatic SMS/WhatsApp/Telegram sending.
- Rebranding or major visual redesign away from the current PWA identity.

## Acceptance Criteria

- A Flutter app can be built for iOS and Android from the new app directory.
- The app starts with onboarding for local profile, PIN/biometric setup, permissions, and AI consent.
- All PWA pages are represented in the feature matrix with planned Flutter equivalents.
- Local storage works without Base44 or network access.
- Health data is protected by local encryption and app unlock.
- Core reminders are scheduled through native local notifications.
- Emergency profile and QR code work offline.
- Emergency contact actions use native platform handoff.
- AI features work online after consent and fail clearly without network.
- The Flutter UI preserves the current Gesundheit Plus layout, red/white health visual language, gradient action tiles, and medical icon semantics.
