import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gesundheitplus/src/app/app_router.dart';

void main() {
  test('router includes all feature parity routes', () {
    final paths = appRouter.configuration.routes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toSet();
    expect(
      paths,
      containsAll([
        '/',
        '/dashboard/health',
        '/health/anamnesis',
        '/health/treatments',
        '/health/professionals',
        '/appointments',
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
      ]),
    );
  });
}
