import 'package:go_router/go_router.dart';

import '../features/care/presentation/dementia_support_screen.dart';
import '../features/care/presentation/family_circle_screen.dart';
import '../features/communication/presentation/communication_settings_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/presentation/health_dashboard_screen.dart';
import '../features/appointments/presentation/appointments_screen.dart';
import '../features/appointments/presentation/healthcare_professionals_screen.dart';
import '../features/documents/presentation/document_scan_screen.dart';
import '../features/documents/presentation/documents_screen.dart';
import '../features/documents/presentation/export_screen.dart';
import '../features/emergency/domain/emergency_payload_builder.dart';
import '../features/emergency/domain/emergency_profile.dart';
import '../features/emergency/presentation/emergency_offline_screen.dart';
import '../features/emergency/presentation/emergency_profile_screen.dart';
import '../features/emergency/presentation/emergency_setup_screen.dart';
import '../features/health_record/presentation/anamnesis_screen.dart';
import '../features/health_record/presentation/treatment_history_screen.dart';
import '../features/medication/presentation/medication_daily_plan_screen.dart';
import '../features/medication/presentation/medication_screen.dart';
import '../features/notifications/presentation/notification_center_screen.dart';
import '../features/prevention/presentation/preventive_care_screen.dart';
import '../features/prevention/presentation/vaccination_screen.dart';
import '../features/privacy/presentation/privacy_screen.dart';
import '../features/privacy/presentation/storage_mode_screen.dart';
import '../features/vitals/presentation/blood_pressure_screen.dart';
import '../features/vitals/presentation/weight_screen.dart';
import '../shared_ui/feature_shell_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(
      path: '/dashboard/health',
      builder: (context, state) => const HealthDashboardScreen(),
    ),
    GoRoute(
      path: '/health/anamnesis',
      builder: (context, state) => const AnamnesisScreen(),
    ),
    GoRoute(
      path: '/health/treatments',
      builder: (context, state) => const TreatmentHistoryScreen(),
    ),
    GoRoute(
      path: '/health/professionals',
      builder: (context, state) => const HealthcareProfessionalsScreen(),
    ),
    GoRoute(
      path: '/appointments',
      builder: (context, state) => const AppointmentsScreen(),
    ),
    GoRoute(
      path: '/medication',
      builder: (context, state) => const MedicationScreen(),
    ),
    GoRoute(
      path: '/medication/daily-plan',
      builder: (context, state) => const MedicationDailyPlanScreen(),
    ),
    GoRoute(
      path: '/medication/interactions',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Medikations-Interaktionen'),
    ),
    GoRoute(
      path: '/medication/interaction-checker',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Wechselwirkungen-Checker'),
    ),
    GoRoute(
      path: '/vitals/blood-pressure',
      builder: (context, state) => const BloodPressureScreen(),
    ),
    GoRoute(
      path: '/vitals/weight',
      builder: (context, state) => const WeightScreen(),
    ),
    GoRoute(
      path: '/prevention/vaccination',
      builder: (context, state) => const VaccinationScreen(),
    ),
    GoRoute(
      path: '/prevention/care',
      builder: (context, state) => const PreventiveCareScreen(),
    ),
    GoRoute(
      path: '/emergency/profile',
      builder: (context, state) =>
          EmergencyProfileScreen(payload: _demoEmergencyPayload()),
    ),
    GoRoute(
      path: '/emergency/setup',
      builder: (context, state) => const EmergencySetupScreen(),
    ),
    GoRoute(
      path: '/emergency/offline',
      builder: (context, state) => const EmergencyOfflineScreen(),
    ),
    GoRoute(
      path: '/documents/scan',
      builder: (context, state) => const DocumentScanScreen(),
    ),
    GoRoute(
      path: '/documents',
      builder: (context, state) => const DocumentsScreen(),
    ),
    GoRoute(path: '/export', builder: (context, state) => const ExportScreen()),
    GoRoute(
      path: '/family',
      builder: (context, state) => const FamilyCircleScreen(),
    ),
    GoRoute(
      path: '/dementia',
      builder: (context, state) => const DementiaSupportScreen(),
    ),
    GoRoute(
      path: '/ai/coach',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'KI-Gesundheitscoach'),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationCenterScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyScreen(),
    ),
    GoRoute(
      path: '/privacy/storage',
      builder: (context, state) => const StorageModeScreen(),
    ),
    GoRoute(
      path: '/settings/telegram',
      builder: (context, state) => const CommunicationSettingsScreen(
        channel: 'telegram',
        title: 'Telegram-Setup',
      ),
    ),
    GoRoute(
      path: '/settings/sms',
      builder: (context, state) =>
          const CommunicationSettingsScreen(channel: 'sms', title: 'SMS-Setup'),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Onboarding'),
    ),
  ],
);

String _demoEmergencyPayload() {
  return EmergencyPayloadBuilder().build(
    const EmergencyProfile(
      fullName: 'Patient',
      notes: 'Lokales Notfallprofil',
      medications: [],
      allergies: [],
      diagnoses: [],
      contacts: [],
    ),
  );
}
