import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/medication/presentation/medication_screen.dart';
import '../shared_ui/feature_shell_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(
      path: '/dashboard/health',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Gesundheits-Dashboard'),
    ),
    GoRoute(
      path: '/health/anamnesis',
      builder: (context, state) => const FeatureShellScreen(title: 'Anamnese'),
    ),
    GoRoute(
      path: '/health/treatments',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Behandlungshistorie'),
    ),
    GoRoute(
      path: '/health/professionals',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Heilberufe'),
    ),
    GoRoute(
      path: '/medication',
      builder: (context, state) => const MedicationScreen(),
    ),
    GoRoute(
      path: '/medication/daily-plan',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Medikamenten-Tagesplan'),
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
      builder: (context, state) => const FeatureShellScreen(title: 'Blutdruck'),
    ),
    GoRoute(
      path: '/vitals/weight',
      builder: (context, state) => const FeatureShellScreen(title: 'Gewicht'),
    ),
    GoRoute(
      path: '/prevention/vaccination',
      builder: (context, state) => const FeatureShellScreen(title: 'Impfpass'),
    ),
    GoRoute(
      path: '/prevention/care',
      builder: (context, state) => const FeatureShellScreen(title: 'Vorsorge'),
    ),
    GoRoute(
      path: '/emergency/profile',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Notfallprofil'),
    ),
    GoRoute(
      path: '/emergency/setup',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Notfall-Einrichtung'),
    ),
    GoRoute(
      path: '/emergency/offline',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Offline-Notfall'),
    ),
    GoRoute(
      path: '/documents/scan',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Dokumenten-Scan'),
    ),
    GoRoute(
      path: '/documents',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Gescannte-Dokumente'),
    ),
    GoRoute(
      path: '/export',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Daten-Export'),
    ),
    GoRoute(
      path: '/family',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Familien-Kreis'),
    ),
    GoRoute(
      path: '/dementia',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Demenz-Unterstuetzung'),
    ),
    GoRoute(
      path: '/ai/coach',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'KI-Gesundheitscoach'),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Benachrichtigungen'),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Datenschutz'),
    ),
    GoRoute(
      path: '/privacy/storage',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Speicher-Modus'),
    ),
    GoRoute(
      path: '/settings/telegram',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Telegram-Setup'),
    ),
    GoRoute(
      path: '/settings/sms',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Twilio-Setup'),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) =>
          const FeatureShellScreen(title: 'Onboarding'),
    ),
  ],
);
