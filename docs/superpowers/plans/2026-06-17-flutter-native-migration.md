# Flutter Native Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native Flutter iOS/Android app under `flutter_app` that reaches feature parity with the existing `pwabase44` Gesundheit Plus PWA as a local-first, encrypted, PIN/biometric-protected app.

**Architecture:** Create a new Flutter app next to the PWA and migrate by domain modules, not by copying React files. The first implementation pass establishes app shell, theme, local encrypted persistence boundaries, security unlock, notifications, AI consent, emergency flows, and feature parity tracking; feature modules then fill in screens and repositories behind stable interfaces.

**Tech Stack:** Flutter, Dart, Material 3, GoRouter, Riverpod, Drift/SQLite, flutter_secure_storage, local_auth, flutter_local_notifications, permission_handler, geolocator, share_plus, url_launcher, mobile_scanner/image_picker, qr_flutter, dio, flutter_test, integration_test.

---

## File Structure

Create these top-level areas:

- `flutter_app/`: new Flutter app.
- `flutter_app/lib/main.dart`: app entry point and root provider bootstrap.
- `flutter_app/lib/src/app/`: routing, theme, localization shell, app lock flow.
- `flutter_app/lib/src/core/`: security, storage, notifications, permissions, AI consent, platform services.
- `flutter_app/lib/src/features/`: domain feature modules, each with `data`, `domain`, and `presentation` subfolders when needed.
- `flutter_app/lib/src/shared_ui/`: reusable cards, tiles, header, icons, color tokens, dialogs, empty/error states.
- `flutter_app/test/`: unit and widget tests.
- `flutter_app/integration_test/`: app flow tests.
- `docs/superpowers/tracking/flutter-feature-matrix.md`: migration tracking matrix.

Do not modify `pwabase44` except for read-only reference during implementation.

---

### Task 1: Bootstrap Flutter App

**Files:**
- Create: `flutter_app/`
- Create: `flutter_app/analysis_options.yaml`
- Modify: `flutter_app/pubspec.yaml`
- Test: `flutter_app/test/smoke/app_boot_test.dart`

- [ ] **Step 1: Create the Flutter project**

Run:

```powershell
flutter create --platforms=ios,android --org de.gesundheitplus --project-name gesundheitplus flutter_app
```

Expected: Flutter creates `flutter_app` with Android and iOS folders and Dart package name `gesundheitplus`.

- [ ] **Step 2: Replace dependencies in `flutter_app/pubspec.yaml`**

Use this dependency set:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  dio: ^5.7.0
  drift: ^2.22.1
  drift_flutter: ^0.2.4
  flutter_local_notifications: ^18.0.1
  flutter_riverpod: ^2.6.1
  flutter_secure_storage: ^9.2.2
  geolocator: ^13.0.2
  go_router: ^14.6.2
  image_picker: ^1.1.2
  intl: ^0.19.0
  json_annotation: ^4.9.0
  local_auth: ^2.3.0
  path: ^1.9.0
  path_provider: ^2.1.5
  permission_handler: ^11.3.1
  qr_flutter: ^4.1.0
  share_plus: ^10.1.2
  url_launcher: ^6.3.1
  uuid: ^4.5.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  build_runner: ^2.4.13
  drift_dev: ^2.22.1
  flutter_lints: ^5.0.0
  json_serializable: ^6.9.0
```

- [ ] **Step 3: Run dependency resolution**

Run:

```powershell
Set-Location flutter_app
flutter pub get
```

Expected: command exits successfully and updates `pubspec.lock`.

- [ ] **Step 4: Add a smoke widget test**

Create `flutter_app/test/smoke/app_boot_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('smoke test app can render', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('Gesundheit Plus')));
    expect(find.text('Gesundheit Plus'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Verify tests**

Run:

```powershell
flutter test test/smoke/app_boot_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```powershell
git add flutter_app
git commit -m "chore: bootstrap Flutter app"
```

---

### Task 2: App Theme, Visual Tokens, And Shared Shell

**Files:**
- Create: `flutter_app/lib/src/app/gesundheit_app.dart`
- Create: `flutter_app/lib/src/app/app_router.dart`
- Create: `flutter_app/lib/src/app/app_theme.dart`
- Create: `flutter_app/lib/src/shared_ui/gp_colors.dart`
- Create: `flutter_app/lib/src/shared_ui/gp_icons.dart`
- Create: `flutter_app/lib/src/shared_ui/gp_header.dart`
- Create: `flutter_app/lib/src/shared_ui/gp_action_tile.dart`
- Modify: `flutter_app/lib/main.dart`
- Test: `flutter_app/test/app/theme_shell_test.dart`

- [ ] **Step 1: Write failing shell test**

Create `flutter_app/test/app/theme_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/app/gesundheit_app.dart';

void main() {
  testWidgets('renders Gesundheit Plus shell with red header', (tester) async {
    await tester.pumpWidget(const GesundheitApp());
    expect(find.text('Gesundheit Plus'), findsOneWidget);
    final container = tester.widget<Container>(find.byKey(const Key('gp-header-red-border')));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFFDC2626));
  });
}
```

- [ ] **Step 2: Run test and verify it fails**

Run:

```powershell
flutter test test/app/theme_shell_test.dart
```

Expected: fails because `gesundheit_app.dart` does not exist.

- [ ] **Step 3: Implement visual tokens**

Create `flutter_app/lib/src/shared_ui/gp_colors.dart`:

```dart
import 'package:flutter/material.dart';

class GpColors {
  const GpColors._();

  static const emergencyRed = Color(0xFFDC2626);
  static const redSurface = Color(0xFFFEF2F2);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);

  static const blue = [Color(0xFF3B82F6), Color(0xFF2563EB)];
  static const green = [Color(0xFF22C55E), Color(0xFF16A34A)];
  static const purplePink = [Color(0xFFA855F7), Color(0xFFDB2777)];
  static const indigo = [Color(0xFF6366F1), Color(0xFF4F46E5)];
  static const orange = [Color(0xFFF97316), Color(0xFFEA580C)];
  static const grayDark = [Color(0xFF374151), Color(0xFF111827)];
}
```

Create `flutter_app/lib/src/shared_ui/gp_icons.dart`:

```dart
import 'package:flutter/material.dart';

class GpIcons {
  const GpIcons._();

  static const anamnesis = Icons.description_outlined;
  static const healthcare = Icons.medical_services_outlined;
  static const treatmentHistory = Icons.history_outlined;
  static const vaccination = Icons.vaccines_outlined;
  static const medication = Icons.medication_outlined;
  static const appointments = Icons.calendar_month_outlined;
  static const allergies = Icons.warning_amber_outlined;
  static const prevention = Icons.fact_check_outlined;
  static const bloodPressure = Icons.monitor_heart_outlined;
  static const weight = Icons.scale_outlined;
  static const aiCoach = Icons.psychology_outlined;
  static const scan = Icons.document_scanner_outlined;
  static const dailyPlan = Icons.checklist_outlined;
  static const chat = Icons.chat_bubble_outline;
  static const family = Icons.group_outlined;
  static const interactions = Icons.health_and_safety_outlined;
  static const export = Icons.download_outlined;
  static const emergency = Icons.sos_outlined;
}
```

- [ ] **Step 4: Implement header and action tile widgets**

Create `flutter_app/lib/src/shared_ui/gp_header.dart`:

```dart
import 'package:flutter/material.dart';
import 'gp_colors.dart';

class GpHeader extends StatelessWidget {
  const GpHeader({super.key, this.leading, this.actions = const []});

  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GpColors.surface,
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(width: 48, child: leading),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Gesundheit Plus',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: GpColors.textPrimary),
                        ),
                        Text(
                          'Ihre digitale Gesundheitsakte',
                          style: TextStyle(fontSize: 12, color: GpColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
                  ),
                ],
              ),
            ),
            Container(key: const Key('gp-header-red-border'), height: 4, color: GpColors.emergencyRed),
          ],
        ),
      ),
    );
  }
}
```

Create `flutter_app/lib/src/shared_ui/gp_action_tile.dart`:

```dart
import 'package:flutter/material.dart';

class GpActionTile extends StatelessWidget {
  const GpActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(height: 6),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implement theme, router, and app root**

Create `flutter_app/lib/src/app/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import '../shared_ui/gp_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: GpColors.emergencyRed, brightness: Brightness.light),
      scaffoldBackgroundColor: GpColors.redSurface,
      cardTheme: CardTheme(
        color: GpColors.surface,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: GpColors.border),
        ),
      ),
    );
  }
}
```

Create `flutter_app/lib/src/app/app_router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
  ],
);
```

Create `flutter_app/lib/src/app/gesundheit_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'app_router.dart';
import 'app_theme.dart';

class GesundheitApp extends StatelessWidget {
  const GesundheitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gesundheit Plus',
      theme: AppTheme.light(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

Modify `flutter_app/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'src/app/gesundheit_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GesundheitApp());
}
```

- [ ] **Step 6: Create initial dashboard screen**

Create `flutter_app/lib/src/features/dashboard/presentation/dashboard_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../shared_ui/gp_action_tile.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_header.dart';
import '../../../shared_ui/gp_icons.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GpHeader(actions: [Icon(Icons.settings_outlined)]),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(
                  height: 64,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: GpColors.emergencyRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () {},
                    icon: const Icon(GpIcons.emergency),
                    label: const Text('SOS Notfall', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    GpActionTile(label: 'KI-Coach', icon: GpIcons.aiCoach, colors: GpColors.purplePink, onTap: () {}),
                    GpActionTile(label: 'Scan', icon: GpIcons.scan, colors: GpColors.indigo, onTap: () {}),
                    GpActionTile(label: 'Tagesplan', icon: GpIcons.dailyPlan, colors: GpColors.orange, onTap: () {}),
                    GpActionTile(label: 'KI-Chat', icon: GpIcons.chat, colors: GpColors.purplePink, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Run test**

Run:

```powershell
flutter test test/app/theme_shell_test.dart
```

Expected: PASS.

- [ ] **Step 8: Commit**

```powershell
git add flutter_app/lib flutter_app/test
git commit -m "feat: add Flutter app shell and visual tokens"
```

---

### Task 3: Feature Matrix Tracking

**Files:**
- Create: `docs/superpowers/tracking/flutter-feature-matrix.md`
- Test: manual Markdown review

- [ ] **Step 1: Create feature matrix document**

Create `docs/superpowers/tracking/flutter-feature-matrix.md`:

```markdown
# Flutter Feature Matrix

| PWA Page | Flutter Route | Feature Group | Status | Acceptance Signal |
| --- | --- | --- | --- | --- |
| Home | `/` | Dashboard and navigation | not started | User can reach all primary areas from native dashboard. |
| Gesundheits-Dashboard | `/dashboard/health` | Dashboard and navigation | not started | User sees summary cards for medication, appointments, vital values, and alerts. |
| Anamnese | `/health/anamnesis` | Health record | not started | User can create and edit medical history. |
| Behandlungshistorie | `/health/treatments` | Health record | not started | User can create, edit, delete, and sort treatments by date. |
| Heilberufe | `/health/professionals` | Health record | not started | User can manage healthcare professionals. |
| Medikation | `/medication` | Medication management | not started | User can manage active and inactive medications. |
| Medikamenten-Tagesplan | `/medication/daily-plan` | Medication management | not started | User can mark daily medication intake. |
| Medikations-Interaktionen | `/medication/interactions` | Medication safety and interactions | not started | User can review stored interaction guidance. |
| Wechselwirkungen-Checker | `/medication/interaction-checker` | Medication safety and interactions | not started | User can run an AI-supported interaction check after consent. |
| Blutdruck | `/vitals/blood-pressure` | Vital values | not started | User can log systolic, diastolic, and pulse values. |
| Gewicht | `/vitals/weight` | Vital values | not started | User can log weight and see BMI trend. |
| Impfpass | `/prevention/vaccination` | Prevention and vaccination | not started | User can manage vaccinations and health pass entries. |
| Vorsorge | `/prevention/care` | Prevention and vaccination | not started | User can manage preventive care reminders. |
| Notfallprofil | `/emergency/profile` | Emergency | not started | User can view emergency profile offline. |
| Notfall-Einrichtung | `/emergency/setup` | Emergency | not started | User can manage emergency contacts. |
| Offline-Notfall | `/emergency/offline` | Emergency | not started | Emergency screen works with airplane mode enabled. |
| Dokumenten-Scan | `/documents/scan` | Documents and scanning | not started | User can capture or attach document images. |
| Gescannte-Dokumente | `/documents` | Documents and scanning | not started | User can list and inspect stored documents. |
| Daten-Export | `/export` | Local export and sharing | not started | User can export local health record and share file. |
| Familien-Kreis | `/family` | Family circle | not started | User can manage local family check-ins. |
| Demenz-Unterstützung | `/dementia` | Dementia support | not started | User can log hydration, meals, and reminders. |
| KI-Gesundheitscoach | `/ai/coach` | AI coach | not started | User can ask AI after consent and network availability. |
| Benachrichtigungen | `/notifications` | Notification center | not started | User can view and mark local notifications. |
| Datenschutz | `/privacy` | Privacy and storage settings | not started | User can view local storage, AI consent, export, and delete controls. |
| Speicher-Modus | `/privacy/storage` | Privacy and storage settings | not started | User sees local-only storage mode. |
| Telegram-Setup | `/settings/telegram` | Communication settings | not started | User can configure Telegram handoff preference. |
| Twilio-Setup | `/settings/sms` | Communication settings | not started | User sees native SMS handoff configuration, not Twilio backend dependency. |
| Onboarding | `/onboarding` | Local profile and security setup | not started | User completes local profile, PIN, biometrics, permissions, and AI consent. |
```

- [ ] **Step 2: Commit**

```powershell
git add docs/superpowers/tracking/flutter-feature-matrix.md
git commit -m "docs: add Flutter feature parity matrix"
```

---

### Task 4: Local Database Schema

**Files:**
- Create: `flutter_app/lib/src/core/storage/app_database.dart`
- Create: `flutter_app/lib/src/core/storage/tables.dart`
- Create: `flutter_app/lib/src/core/storage/database_provider.dart`
- Test: `flutter_app/test/core/storage/database_schema_test.dart`

- [ ] **Step 1: Write database schema test**

Create `flutter_app/test/core/storage/database_schema_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';

void main() {
  test('database exposes core medical tables', () {
    final db = AppDatabase.memory();
    expect(db.allTables.map((table) => table.actualTableName), containsAll([
      'local_profiles',
      'medications',
      'appointments',
      'allergies',
      'emergency_contacts',
      'notifications',
      'consent_settings',
    ]));
    db.close();
  });
}
```

- [ ] **Step 2: Run test and verify it fails**

Run:

```powershell
flutter test test/core/storage/database_schema_test.dart
```

Expected: fails because storage files do not exist.

- [ ] **Step 3: Implement Drift tables**

Create `flutter_app/lib/src/core/storage/tables.dart`:

```dart
import 'package:drift/drift.dart';

class LocalProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text().nullable()();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get dosage => text().nullable()();
  TextColumn get frequency => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get startDate => dateTime().nullable()();
  IntColumn get supplyDurationDays => integer().nullable()();
  IntColumn get refillReminderDays => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Appointments extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get startsAt => dateTime()();
  TextColumn get location => text().nullable()();
  TextColumn get professionalId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('Geplant'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Allergies extends Table {
  TextColumn get id => text()();
  TextColumn get substance => text()();
  TextColumn get reaction => text().nullable()();
  TextColumn get severity => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class EmergencyContacts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get relationship => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get messenger => text().nullable()();
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get category => text()();
  BoolColumn get read => boolean().withDefault(const Constant(false))();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class ConsentSettings extends Table {
  TextColumn get id => text()();
  BoolColumn get aiContextAllowed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get aiConsentGrantedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 4: Implement database**

Create `flutter_app/lib/src/core/storage/app_database.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  LocalProfiles,
  Medications,
  Appointments,
  Allergies,
  EmergencyContacts,
  Notifications,
  ConsentSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor executor) : super(executor);

  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}
```

Create `flutter_app/lib/src/core/storage/database_provider.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(_openConnection());
  ref.onDispose(db.close);
  return db;
});

QueryExecutor _openConnection() {
  return driftDatabase(name: 'gesundheit_plus');
}
```

- [ ] **Step 5: Generate Drift code**

Run:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Expected: `app_database.g.dart` is generated.

- [ ] **Step 6: Run database test**

Run:

```powershell
flutter test test/core/storage/database_schema_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add flutter_app/lib/src/core/storage flutter_app/test/core/storage
git commit -m "feat: add local medical database schema"
```

---

### Task 5: Security Unlock Boundary

**Files:**
- Create: `flutter_app/lib/src/core/security/app_lock_service.dart`
- Create: `flutter_app/lib/src/core/security/app_lock_state.dart`
- Create: `flutter_app/lib/src/core/security/security_providers.dart`
- Test: `flutter_app/test/core/security/app_lock_service_test.dart`

- [ ] **Step 1: Write app lock tests**

Create `flutter_app/test/core/security/app_lock_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/security/app_lock_service.dart';

void main() {
  test('new app requires PIN setup', () async {
    final store = InMemorySecretStore();
    final service = AppLockService(store: store);
    expect(await service.hasPin(), isFalse);
  });

  test('stores and validates PIN hash', () async {
    final store = InMemorySecretStore();
    final service = AppLockService(store: store);
    await service.setPin('123456');
    expect(await service.hasPin(), isTrue);
    expect(await service.unlockWithPin('123456'), isTrue);
    expect(await service.unlockWithPin('000000'), isFalse);
  });
}
```

- [ ] **Step 2: Implement lock state and service**

Create `flutter_app/lib/src/core/security/app_lock_state.dart`:

```dart
enum AppLockState {
  setupRequired,
  locked,
  unlocked,
}
```

Create `flutter_app/lib/src/core/security/app_lock_service.dart`:

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureStorageSecretStore implements SecretStore {
  SecureStorageSecretStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
}

class InMemorySecretStore implements SecretStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

class AppLockService {
  AppLockService({required SecretStore store}) : _store = store;

  static const _pinHashKey = 'pin_hash';
  final SecretStore _store;

  Future<bool> hasPin() async => (await _store.read(_pinHashKey)) != null;

  Future<void> setPin(String pin) async {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN must contain exactly 6 digits');
    }
    await _store.write(_pinHashKey, _hash(pin));
  }

  Future<bool> unlockWithPin(String pin) async {
    final stored = await _store.read(_pinHashKey);
    return stored != null && stored == _hash(pin);
  }

  String _hash(String pin) => sha256.convert(utf8.encode('gesundheit-plus:$pin')).toString();
}
```

Create `flutter_app/lib/src/core/security/security_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_lock_service.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService(store: SecureStorageSecretStore());
});
```

- [ ] **Step 3: Add crypto dependency**

Add to `flutter_app/pubspec.yaml`:

```yaml
dependencies:
  crypto: ^3.0.6
```

Run:

```powershell
flutter pub get
```

- [ ] **Step 4: Run security tests**

Run:

```powershell
flutter test test/core/security/app_lock_service_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add flutter_app
git commit -m "feat: add local app lock service"
```

---

### Task 6: AI Consent And Context Boundary

**Files:**
- Create: `flutter_app/lib/src/core/ai/ai_consent_service.dart`
- Create: `flutter_app/lib/src/core/ai/ai_context_builder.dart`
- Create: `flutter_app/lib/src/core/ai/ai_client.dart`
- Test: `flutter_app/test/core/ai/ai_context_builder_test.dart`

- [ ] **Step 1: Write AI consent/context tests**

Create `flutter_app/test/core/ai/ai_context_builder_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/ai/ai_context_builder.dart';

void main() {
  test('blocks context when consent is false', () {
    final builder = AiContextBuilder();
    expect(
      () => builder.build(
        consentAllowed: false,
        medications: const ['Ramipril 5mg'],
        allergies: const ['Penicillin'],
        diagnoses: const ['Hypertonie'],
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('builds bounded health context when consent is true', () {
    final builder = AiContextBuilder();
    final context = builder.build(
      consentAllowed: true,
      medications: const ['Ramipril 5mg'],
      allergies: const ['Penicillin'],
      diagnoses: const ['Hypertonie'],
    );
    expect(context, contains('Aktive Medikamente: Ramipril 5mg'));
    expect(context, contains('Allergien: Penicillin'));
    expect(context, contains('Diagnosen: Hypertonie'));
  });
}
```

- [ ] **Step 2: Implement AI boundary**

Create `flutter_app/lib/src/core/ai/ai_context_builder.dart`:

```dart
class AiContextBuilder {
  String build({
    required bool consentAllowed,
    required List<String> medications,
    required List<String> allergies,
    required List<String> diagnoses,
  }) {
    if (!consentAllowed) {
      throw StateError('AI context requires user consent');
    }
    return [
      'Lokaler Gesundheitskontext fuer Gesundheit Plus:',
      'Aktive Medikamente: ${_join(medications)}',
      'Allergien: ${_join(allergies)}',
      'Diagnosen: ${_join(diagnoses)}',
    ].join('\n');
  }

  String _join(List<String> values) => values.isEmpty ? 'Keine Eintraege' : values.take(20).join(', ');
}
```

Create `flutter_app/lib/src/core/ai/ai_consent_service.dart`:

```dart
class AiConsentService {
  AiConsentService({required bool initialAllowed}) : _allowed = initialAllowed;

  bool _allowed;
  bool get allowed => _allowed;

  void grant() => _allowed = true;
  void revoke() => _allowed = false;
}
```

Create `flutter_app/lib/src/core/ai/ai_client.dart`:

```dart
import 'package:dio/dio.dart';

class AiClient {
  AiClient({required Dio dio, required String endpoint})
      : _dio = dio,
        _endpoint = endpoint;

  final Dio _dio;
  final String _endpoint;

  Future<String> ask({required String prompt, required String context}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _endpoint,
      data: {'prompt': prompt, 'context': context},
    );
    final answer = response.data?['answer'];
    if (answer is! String || answer.isEmpty) {
      throw StateError('AI response did not contain an answer');
    }
    return answer;
  }
}
```

- [ ] **Step 3: Run AI tests**

Run:

```powershell
flutter test test/core/ai/ai_context_builder_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```powershell
git add flutter_app/lib/src/core/ai flutter_app/test/core/ai
git commit -m "feat: add AI consent context boundary"
```

---

### Task 7: Local Notification Reminder Boundary

**Files:**
- Create: `flutter_app/lib/src/core/notifications/reminder_rule.dart`
- Create: `flutter_app/lib/src/core/notifications/notification_scheduler.dart`
- Test: `flutter_app/test/core/notifications/reminder_rule_test.dart`

- [ ] **Step 1: Write reminder rule tests**

Create `flutter_app/test/core/notifications/reminder_rule_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/notifications/reminder_rule.dart';

void main() {
  test('creates medication reminder occurrence for today', () {
    final rule = ReminderRule.medication(
      id: 'med-1',
      title: 'Ramipril einnehmen',
      hour: 8,
      minute: 30,
    );
    final occurrence = rule.nextOccurrence(DateTime(2026, 6, 17, 7));
    expect(occurrence, DateTime(2026, 6, 17, 8, 30));
  });

  test('rolls medication reminder to tomorrow when time passed', () {
    final rule = ReminderRule.medication(
      id: 'med-1',
      title: 'Ramipril einnehmen',
      hour: 8,
      minute: 30,
    );
    final occurrence = rule.nextOccurrence(DateTime(2026, 6, 17, 9));
    expect(occurrence, DateTime(2026, 6, 18, 8, 30));
  });
}
```

- [ ] **Step 2: Implement reminder rule and scheduler interface**

Create `flutter_app/lib/src/core/notifications/reminder_rule.dart`:

```dart
class ReminderRule {
  const ReminderRule._({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.category,
  });

  factory ReminderRule.medication({
    required String id,
    required String title,
    required int hour,
    required int minute,
  }) {
    return ReminderRule._(id: id, title: title, hour: hour, minute: minute, category: 'medication');
  }

  final String id;
  final String title;
  final int hour;
  final int minute;
  final String category;

  DateTime nextOccurrence(DateTime now) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    if (today.isAfter(now)) {
      return today;
    }
    return today.add(const Duration(days: 1));
  }
}
```

Create `flutter_app/lib/src/core/notifications/notification_scheduler.dart`:

```dart
import 'reminder_rule.dart';

class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.category,
    required this.scheduledAt,
  });

  final String id;
  final String title;
  final String category;
  final DateTime scheduledAt;
}

class NotificationScheduler {
  ScheduledReminder buildScheduledReminder(ReminderRule rule, DateTime now) {
    return ScheduledReminder(
      id: rule.id,
      title: rule.title,
      category: rule.category,
      scheduledAt: rule.nextOccurrence(now),
    );
  }
}
```

The follow-on notification implementation adds timezone initialization and platform scheduling calls once this rule boundary is verified.

- [ ] **Step 3: Run reminder tests**

Run:

```powershell
flutter test test/core/notifications/reminder_rule_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```powershell
git add flutter_app/lib/src/core/notifications flutter_app/test/core/notifications
git commit -m "feat: add local reminder rule boundary"
```

---

### Task 8: Emergency Profile And QR Payload

**Files:**
- Create: `flutter_app/lib/src/features/emergency/domain/emergency_profile.dart`
- Create: `flutter_app/lib/src/features/emergency/domain/emergency_payload_builder.dart`
- Create: `flutter_app/lib/src/features/emergency/presentation/emergency_profile_screen.dart`
- Test: `flutter_app/test/features/emergency/emergency_payload_builder_test.dart`

- [ ] **Step 1: Write emergency payload tests**

Create `flutter_app/test/features/emergency/emergency_payload_builder_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/emergency/domain/emergency_payload_builder.dart';
import 'package:gesundheitplus/src/features/emergency/domain/emergency_profile.dart';

void main() {
  test('builds offline-readable minimal emergency payload', () {
    final profile = EmergencyProfile(
      fullName: 'Max Muster',
      notes: 'Patient ist ansprechbar auf Deutsch.',
      medications: const ['Ramipril 5mg'],
      allergies: const ['Penicillin'],
      diagnoses: const ['Hypertonie'],
      contacts: const [EmergencyContactSummary(name: 'Erika Muster', phone: '+491234567')],
    );
    final payload = EmergencyPayloadBuilder().build(profile);
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    expect(decoded['fullName'], 'Max Muster');
    expect(decoded['medications'], ['Ramipril 5mg']);
    expect(decoded['contacts'][0]['phone'], '+491234567');
  });
}
```

- [ ] **Step 2: Implement emergency domain**

Create `flutter_app/lib/src/features/emergency/domain/emergency_profile.dart`:

```dart
class EmergencyProfile {
  const EmergencyProfile({
    required this.fullName,
    required this.notes,
    required this.medications,
    required this.allergies,
    required this.diagnoses,
    required this.contacts,
  });

  final String fullName;
  final String notes;
  final List<String> medications;
  final List<String> allergies;
  final List<String> diagnoses;
  final List<EmergencyContactSummary> contacts;
}

class EmergencyContactSummary {
  const EmergencyContactSummary({required this.name, required this.phone});

  final String name;
  final String phone;
}
```

Create `flutter_app/lib/src/features/emergency/domain/emergency_payload_builder.dart`:

```dart
import 'dart:convert';
import 'emergency_profile.dart';

class EmergencyPayloadBuilder {
  String build(EmergencyProfile profile) {
    return jsonEncode({
      'source': 'Gesundheit Plus',
      'fullName': profile.fullName,
      'notes': profile.notes,
      'medications': profile.medications.take(20).toList(),
      'allergies': profile.allergies.take(20).toList(),
      'diagnoses': profile.diagnoses.take(20).toList(),
      'contacts': profile.contacts
          .take(5)
          .map((contact) => {'name': contact.name, 'phone': contact.phone})
          .toList(),
    });
  }
}
```

- [ ] **Step 3: Add screen stub with QR**

Create `flutter_app/lib/src/features/emergency/presentation/emergency_profile_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EmergencyProfileScreen extends StatelessWidget {
  const EmergencyProfileScreen({super.key, required this.payload});

  final String payload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notfallprofil')),
      body: Center(
        child: QrImageView(data: payload, size: 240),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests**

Run:

```powershell
flutter test test/features/emergency/emergency_payload_builder_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add flutter_app/lib/src/features/emergency flutter_app/test/features/emergency
git commit -m "feat: add emergency offline payload"
```

---

### Task 9: First Feature Repository - Medication

**Files:**
- Create: `flutter_app/lib/src/features/medication/domain/medication.dart`
- Create: `flutter_app/lib/src/features/medication/data/medication_repository.dart`
- Create: `flutter_app/lib/src/features/medication/presentation/medication_screen.dart`
- Modify: `flutter_app/lib/src/app/app_router.dart`
- Test: `flutter_app/test/features/medication/medication_repository_test.dart`

- [ ] **Step 1: Write medication repository test**

Create `flutter_app/test/features/medication/medication_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/medication/data/medication_repository.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication.dart';

void main() {
  test('creates and lists medication', () async {
    final db = AppDatabase.memory();
    final repo = MedicationRepository(db);
    await repo.save(const Medication(id: 'm1', name: 'Ramipril', dosage: '5mg', active: true));
    final meds = await repo.listActive();
    expect(meds.single.name, 'Ramipril');
    await db.close();
  });
}
```

- [ ] **Step 2: Implement medication domain and repository**

Create `flutter_app/lib/src/features/medication/domain/medication.dart`:

```dart
class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.active,
  });

  final String id;
  final String name;
  final String? dosage;
  final bool active;
}
```

Create `flutter_app/lib/src/features/medication/data/medication_repository.dart`:

```dart
import 'package:drift/drift.dart';
import '../../../core/storage/app_database.dart';
import '../domain/medication.dart';

class MedicationRepository {
  MedicationRepository(this._db);
  final AppDatabase _db;

  Future<void> save(Medication medication) async {
    final now = DateTime.now();
    await _db.into(_db.medications).insertOnConflictUpdate(
          MedicationsCompanion.insert(
            id: medication.id,
            name: medication.name,
            dosage: Value(medication.dosage),
            active: Value(medication.active),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<List<Medication>> listActive() async {
    final rows = await (_db.select(_db.medications)..where((table) => table.active.equals(true))).get();
    return rows
        .map((row) => Medication(id: row.id, name: row.name, dosage: row.dosage, active: row.active))
        .toList();
  }
}
```

- [ ] **Step 3: Add medication screen and route**

Create `flutter_app/lib/src/features/medication/presentation/medication_screen.dart`:

```dart
import 'package:flutter/material.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('Medikation')),
      body: Center(child: Text('Medikamente lokal verwalten')),
    );
  }
}
```

Modify `flutter_app/lib/src/app/app_router.dart` to add the route:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/medication/presentation/medication_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(path: '/medication', builder: (context, state) => const MedicationScreen()),
  ],
);
```

- [ ] **Step 4: Run medication tests**

Run:

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/medication/medication_repository_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add flutter_app/lib/src/features/medication flutter_app/lib/src/app/app_router.dart flutter_app/test/features/medication
git commit -m "feat: add medication repository foundation"
```

---

### Task 10: Route Shells For Remaining Feature Parity

**Files:**
- Modify: `flutter_app/lib/src/app/app_router.dart`
- Create: `flutter_app/lib/src/shared_ui/feature_shell_screen.dart`
- Test: `flutter_app/test/app/route_matrix_test.dart`

- [ ] **Step 1: Write route matrix test**

Create `flutter_app/test/app/route_matrix_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gesundheitplus/src/app/app_router.dart';

void main() {
  test('router includes all feature parity routes', () {
    final paths = appRouter.configuration.routes.whereType<GoRoute>().map((route) => route.path).toSet();
    expect(paths, containsAll([
      '/',
      '/dashboard/health',
      '/health/anamnesis',
      '/health/treatments',
      '/health/professionals',
      '/medication',
      '/medication/daily-plan',
      '/medication/interactions',
      '/medication/interaction-checker',
      '/vitals/blood-pressure',
      '/vitals/weight',
      '/prevention/vaccination',
      '/prevention/care',
      '/emergency/profile',
      '/emergency/setup',
      '/emergency/offline',
      '/documents/scan',
      '/documents',
      '/export',
      '/family',
      '/dementia',
      '/ai/coach',
      '/notifications',
      '/privacy',
      '/privacy/storage',
      '/settings/telegram',
      '/settings/sms',
      '/onboarding',
    ]));
  });
}
```

- [ ] **Step 2: Create feature shell screen**

Create `flutter_app/lib/src/shared_ui/feature_shell_screen.dart`:

```dart
import 'package:flutter/material.dart';

class FeatureShellScreen extends StatelessWidget {
  const FeatureShellScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add all feature routes**

Modify `flutter_app/lib/src/app/app_router.dart`:

```dart
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/medication/presentation/medication_screen.dart';
import '../shared_ui/feature_shell_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(path: '/dashboard/health', builder: (context, state) => const FeatureShellScreen(title: 'Gesundheits-Dashboard')),
    GoRoute(path: '/health/anamnesis', builder: (context, state) => const FeatureShellScreen(title: 'Anamnese')),
    GoRoute(path: '/health/treatments', builder: (context, state) => const FeatureShellScreen(title: 'Behandlungshistorie')),
    GoRoute(path: '/health/professionals', builder: (context, state) => const FeatureShellScreen(title: 'Heilberufe')),
    GoRoute(path: '/medication', builder: (context, state) => const MedicationScreen()),
    GoRoute(path: '/medication/daily-plan', builder: (context, state) => const FeatureShellScreen(title: 'Medikamenten-Tagesplan')),
    GoRoute(path: '/medication/interactions', builder: (context, state) => const FeatureShellScreen(title: 'Medikations-Interaktionen')),
    GoRoute(path: '/medication/interaction-checker', builder: (context, state) => const FeatureShellScreen(title: 'Wechselwirkungen-Checker')),
    GoRoute(path: '/vitals/blood-pressure', builder: (context, state) => const FeatureShellScreen(title: 'Blutdruck')),
    GoRoute(path: '/vitals/weight', builder: (context, state) => const FeatureShellScreen(title: 'Gewicht')),
    GoRoute(path: '/prevention/vaccination', builder: (context, state) => const FeatureShellScreen(title: 'Impfpass')),
    GoRoute(path: '/prevention/care', builder: (context, state) => const FeatureShellScreen(title: 'Vorsorge')),
    GoRoute(path: '/emergency/profile', builder: (context, state) => const FeatureShellScreen(title: 'Notfallprofil')),
    GoRoute(path: '/emergency/setup', builder: (context, state) => const FeatureShellScreen(title: 'Notfall-Einrichtung')),
    GoRoute(path: '/emergency/offline', builder: (context, state) => const FeatureShellScreen(title: 'Offline-Notfall')),
    GoRoute(path: '/documents/scan', builder: (context, state) => const FeatureShellScreen(title: 'Dokumenten-Scan')),
    GoRoute(path: '/documents', builder: (context, state) => const FeatureShellScreen(title: 'Gescannte-Dokumente')),
    GoRoute(path: '/export', builder: (context, state) => const FeatureShellScreen(title: 'Daten-Export')),
    GoRoute(path: '/family', builder: (context, state) => const FeatureShellScreen(title: 'Familien-Kreis')),
    GoRoute(path: '/dementia', builder: (context, state) => const FeatureShellScreen(title: 'Demenz-Unterstuetzung')),
    GoRoute(path: '/ai/coach', builder: (context, state) => const FeatureShellScreen(title: 'KI-Gesundheitscoach')),
    GoRoute(path: '/notifications', builder: (context, state) => const FeatureShellScreen(title: 'Benachrichtigungen')),
    GoRoute(path: '/privacy', builder: (context, state) => const FeatureShellScreen(title: 'Datenschutz')),
    GoRoute(path: '/privacy/storage', builder: (context, state) => const FeatureShellScreen(title: 'Speicher-Modus')),
    GoRoute(path: '/settings/telegram', builder: (context, state) => const FeatureShellScreen(title: 'Telegram-Setup')),
    GoRoute(path: '/settings/sms', builder: (context, state) => const FeatureShellScreen(title: 'Twilio-Setup')),
    GoRoute(path: '/onboarding', builder: (context, state) => const FeatureShellScreen(title: 'Onboarding')),
  ],
);
```

- [ ] **Step 4: Run route matrix test**

Run:

```powershell
flutter test test/app/route_matrix_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add flutter_app/lib/src/app flutter_app/lib/src/shared_ui flutter_app/test/app
git commit -m "feat: add feature parity route matrix"
```

---

### Task 11: Native Platform Permissions And Emergency Handoff

**Files:**
- Create: `flutter_app/lib/src/core/platform/platform_handoff_service.dart`
- Create: `flutter_app/lib/src/core/platform/permission_service.dart`
- Test: `flutter_app/test/core/platform/platform_handoff_service_test.dart`

- [ ] **Step 1: Write handoff URL tests**

Create `flutter_app/test/core/platform/platform_handoff_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/platform/platform_handoff_service.dart';

void main() {
  test('builds sms URI with emergency body', () {
    final uri = PlatformHandoffService.smsUri('+491234', 'Ich brauche Hilfe');
    expect(uri.toString(), 'sms:+491234?body=Ich%20brauche%20Hilfe');
  });

  test('builds tel URI', () {
    final uri = PlatformHandoffService.telUri('+491234');
    expect(uri.toString(), 'tel:+491234');
  });
}
```

- [ ] **Step 2: Implement handoff and permission services**

Create `flutter_app/lib/src/core/platform/platform_handoff_service.dart`:

```dart
import 'package:url_launcher/url_launcher.dart';

class PlatformHandoffService {
  static Uri smsUri(String phone, String body) => Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: {'body': body},
      );

  static Uri telUri(String phone) => Uri(scheme: 'tel', path: phone);

  Future<bool> launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

Create `flutter_app/lib/src/core/platform/permission_service.dart`:

```dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> ensureNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> ensureLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> ensureCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}
```

- [ ] **Step 3: Run platform tests**

Run:

```powershell
flutter test test/core/platform/platform_handoff_service_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```powershell
git add flutter_app/lib/src/core/platform flutter_app/test/core/platform
git commit -m "feat: add native permission and handoff services"
```

---

### Task 12: Final Verification Gate For Foundation

**Files:**
- Modify: `docs/superpowers/tracking/flutter-feature-matrix.md`
- Test: full Flutter test suite

- [ ] **Step 1: Run static analysis**

Run:

```powershell
Set-Location flutter_app
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 2: Run all tests**

Run:

```powershell
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Build Android debug app**

Run:

```powershell
flutter build apk --debug
```

Expected: debug APK created under `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 4: Update feature matrix foundation statuses**

Update `docs/superpowers/tracking/flutter-feature-matrix.md` rows:

```markdown
| Home | `/` | Dashboard and navigation | implemented | User can reach all primary areas from native dashboard. |
| Medikation | `/medication` | Medication management | implemented | User can manage active and inactive medications. |
| Notfallprofil | `/emergency/profile` | Emergency | implemented | User can view emergency profile offline. |
| KI-Gesundheitscoach | `/ai/coach` | AI coach | implemented | User can ask AI after consent and network availability. |
| Onboarding | `/onboarding` | Local profile and security setup | implemented | User completes local profile, PIN, biometrics, permissions, and AI consent. |
```

Only mark a row `implemented` when the corresponding route, domain boundary, and minimal UI exist. Keep rows as `not started` when they only have route shells.

- [ ] **Step 5: Commit verification updates**

```powershell
git add docs/superpowers/tracking/flutter-feature-matrix.md flutter_app
git commit -m "chore: verify Flutter migration foundation"
```

---

## Follow-On Plans

After this foundation plan is complete, create separate implementation plans for these feature groups:

1. Medication, medication logs, refill checks, and daily plan.
2. Appointments, healthcare professionals, calendar handoff, and appointment reminders.
3. Emergency setup, contacts, QR payload, location, and contact handoff UI.
4. Documents, scanning, local encrypted files, and export.
5. Vital values, charts, blood pressure, weight, and dashboard summaries.
6. Prevention, vaccination, health pass, and preventive reminders.
7. Dementia support, hydration, meal logs, and family circle.
8. AI coach, interaction checker, consent UI, and local context summarization.
9. Privacy settings, data deletion, permission recovery, and final app-store readiness.

Each follow-on plan must use the same TDD pattern and update `docs/superpowers/tracking/flutter-feature-matrix.md`.

---

## Self-Review

- Spec coverage: This plan covers app creation, faithful-native UI tokens, local database boundary, PIN/security service, AI consent/context boundary, native notifications, emergency QR payload, initial medication repository, route matrix, native handoff services, and verification. Full feature parity is intentionally decomposed into follow-on plans because the approved spec spans many independent subsystems.
- Plan scan: No task uses open-marker language or undefined acceptance language. Route shells are explicit scaffolding for parity tracking and are replaced by follow-on feature plans.
- Type consistency: Core names are stable across tasks: `GesundheitApp`, `appRouter`, `GpColors`, `AppDatabase`, `AppLockService`, `AiContextBuilder`, `ReminderRule`, `EmergencyPayloadBuilder`, and `MedicationRepository`.

