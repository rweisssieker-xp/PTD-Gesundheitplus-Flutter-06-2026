# Flutter Feature Matrix

| PWA Page | Flutter Route | Feature Group | Status | Acceptance Signal |
| --- | --- | --- | --- | --- |
| Home | `/` | Dashboard and navigation | implemented | User can reach primary dashboard actions from native dashboard. |
| Gesundheits-Dashboard | `/dashboard/health` | Dashboard and navigation | not started | User sees summary cards for medication, appointments, vital values, and alerts. |
| Anamnese | `/health/anamnesis` | Health record | not started | User can create and edit medical history. |
| Behandlungshistorie | `/health/treatments` | Health record | not started | User can create, edit, delete, and sort treatments by date. |
| Heilberufe | `/health/professionals` | Health record | implemented | User can create, list, and delete local healthcare professionals. |
| Termine | `/appointments` | Appointments | implemented | User can create, list, complete, and delete local appointments. |
| Medikation | `/medication` | Medication management | implemented | User can add, edit, deactivate, delete, and list local medications with reminder times. |
| Medikamenten-Tagesplan | `/medication/daily-plan` | Medication management | implemented | User can generate daily medication logs and mark intake as taken or skipped. |
| Medikations-Interaktionen | `/medication/interactions` | Medication safety and interactions | not started | User can review stored interaction guidance. |
| Wechselwirkungen-Checker | `/medication/interaction-checker` | Medication safety and interactions | not started | User can run an AI-supported interaction check after consent. |
| Blutdruck | `/vitals/blood-pressure` | Vital values | not started | User can log systolic, diastolic, and pulse values. |
| Gewicht | `/vitals/weight` | Vital values | not started | User can log weight and see BMI trend. |
| Impfpass | `/prevention/vaccination` | Prevention and vaccination | not started | User can manage vaccinations and health pass entries. |
| Vorsorge | `/prevention/care` | Prevention and vaccination | not started | User can manage preventive care reminders. |
| Notfallprofil | `/emergency/profile` | Emergency | implemented | Offline emergency payload builder, QR screen, route, and test coverage exist. |
| Notfall-Einrichtung | `/emergency/setup` | Emergency | not started | User can manage emergency contacts. |
| Offline-Notfall | `/emergency/offline` | Emergency | not started | Emergency screen works with airplane mode enabled. |
| Dokumenten-Scan | `/documents/scan` | Documents and scanning | not started | User can capture or attach document images. |
| Gescannte-Dokumente | `/documents` | Documents and scanning | not started | User can list and inspect stored documents. |
| Daten-Export | `/export` | Local export and sharing | not started | User can export local health record and share file. |
| Familien-Kreis | `/family` | Family circle | not started | User can manage local family check-ins. |
| Demenz-Unterstuetzung | `/dementia` | Dementia support | not started | User can log hydration, meals, and reminders. |
| KI-Gesundheitscoach | `/ai/coach` | AI coach | not started | User can ask AI after consent and network availability. |
| Benachrichtigungen | `/notifications` | Notification center | not started | User can view and mark local notifications. |
| Datenschutz | `/privacy` | Privacy and storage settings | not started | User can view local storage, AI consent, export, and delete controls. |
| Speicher-Modus | `/privacy/storage` | Privacy and storage settings | not started | User sees local-only storage mode. |
| Telegram-Setup | `/settings/telegram` | Communication settings | not started | User can configure Telegram handoff preference. |
| Twilio-Setup | `/settings/sms` | Communication settings | not started | User sees native SMS handoff configuration, not Twilio backend dependency. |
| Onboarding | `/onboarding` | Local profile and security setup | not started | User completes local profile, PIN, biometrics, permissions, and AI consent. |
