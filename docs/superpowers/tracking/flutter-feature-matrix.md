# Flutter Feature Matrix

| PWA Page | Flutter Route | Feature Group | Status | Acceptance Signal |
| --- | --- | --- | --- | --- |
| Home | `/` | Dashboard and navigation | implemented | User first sees the PWA-style storage-mode choice, can select local-device storage, and then reaches primary dashboard actions from a native dashboard that mirrors the PWA mobile layout, colors, icons, shell controls, and locally persisted language switching. |
| Gesundheits-Dashboard | `/dashboard/health` | Dashboard and navigation | implemented | User sees local summary cards for medication, appointments, vital values, and alerts. |
| Anamnese | `/health/anamnesis` | Health record | implemented | User can create, list, delete, hear a native read-aloud summary, and share local medical history entries through an offline-readable QR payload. |
| Behandlungshistorie | `/health/treatments` | Health record | implemented | User can create, list, delete, sort treatments by date, and hear a native read-aloud summary. |
| Heilberufe | `/health/professionals` | Health record | implemented | User can search local specialty/provider suggestions, add a suggestion to local healthcare professionals, create, list, delete, and hear a native read-aloud summary. |
| Allergien | `/health/allergies` | Health record | implemented | User can create, edit, group, list, hear a native read-aloud summary, run a local medication-allergy conflict check, and delete local allergies with severity warnings. |
| Termine | `/appointments` | Appointments | implemented | User can create, list, complete, delete, hear a native read-aloud summary, schedule native local reminders, turn spoken-style German text into local appointment drafts on-device, and export appointments as local `.ics` calendar files. |
| Medikation | `/medication` | Medication management | implemented | User can add, edit, deactivate, delete, list, capture local supply/refill metadata, turn spoken-style German medication text into local medication drafts on-device, and hear a native read-aloud summary of local medications with native local reminder scheduling and proactive refill alerts. |
| Medikamenten-Tagesplan | `/medication/daily-plan` | Medication management | implemented | User can generate daily medication logs and mark intake as taken or skipped. |
| Medikations-Interaktionen | `/medication/interactions` | Medication safety and interactions | implemented | User can create and review stored local interaction guidance. |
| Wechselwirkungen-Checker | `/medication/interaction-checker` | Medication safety and interactions | implemented | User can run a local consent-gated interaction check against active medication. |
| Blutdruck | `/vitals/blood-pressure` | Vital values | implemented | User can log and list systolic, diastolic, and pulse values locally. |
| Gewicht | `/vitals/weight` | Vital values | implemented | User can log weight locally and see BMI per entry when height is present. |
| Impfpass | `/prevention/vaccination` | Prevention and vaccination | implemented | User can create, list, and hear a native read-aloud summary of local vaccination records with optional booster due date. |
| Vorsorge | `/prevention/care` | Prevention and vaccination | implemented | User can see local age-based vaccination and screening recommendations, turn recommendations into native local preventive-care reminders, create manual reminders, and mark them done. |
| Notfallprofil | `/emergency/profile` | Emergency | implemented | User sees a QR-backed emergency profile built from local records and can use native phone, SMS, and current-location SMS handoff for emergency contacts. |
| Notfall-Einrichtung | `/emergency/setup` | Emergency | implemented | User can create, import from device contacts after permission, verify, list, and delete local emergency contacts. |
| Offline-Notfall | `/emergency/offline` | Emergency | implemented | Emergency screen renders local medication, allergy, contact, QR payload, and native phone/SMS/current-location handoff without backend access. |
| Dokumenten-Scan | `/documents/scan` | Documents and scanning | implemented | User can capture or attach document images, preview local medical insights, and store metadata locally. |
| Gescannte-Dokumente | `/documents` | Documents and scanning | implemented | User can list, expand local medical insights for, and delete locally stored documents. |
| Daten-Export | `/export` | Local export and sharing | implemented | User can export local health record JSON and share the generated file. |
| Familien-Kreis | `/family` | Family circle | implemented | User can manage local family members and send local safety check-ins with optional note and current-device location text. |
| Demenz-Unterstuetzung | `/dementia` | Dementia support | implemented | User can log hydration, meals, and reminders locally with follow-up native local reminders. |
| KI-Gesundheitscoach | `/ai/coach` | AI coach | implemented | User can ask a local consent-gated coach and keep the message history on-device. |
| Benachrichtigungen | `/notifications` | Notification center | implemented | User can view and mark local notifications as read, including deduplicated proactive local alerts for refills, interaction risk, emergency contacts, and incomplete emergency profile data. |
| Datenschutz | `/privacy` | Privacy and storage settings | implemented | User can view local storage count, manage AI context consent, export data, and delete all local data after confirmation. |
| Speicher-Modus | `/privacy/storage` | Privacy and storage settings | implemented | User sees local-only storage mode, per-table local record counts, and can clear local data after confirmation. |
| Telegram-Setup | `/settings/telegram` | Communication settings | implemented | User can configure local Telegram handoff preference. |
| Twilio-Setup | `/settings/sms` | Communication settings | implemented | User sees and stores native SMS handoff configuration without Twilio backend dependency. |
| Onboarding | `/onboarding` | Local profile and security setup | implemented | User completes local profile, PIN, optional biometric unlock when supported, and AI consent setup on-device. |
