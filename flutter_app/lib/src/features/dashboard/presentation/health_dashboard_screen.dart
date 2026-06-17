import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';

class HealthDashboardScreen extends ConsumerWidget {
  const HealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Gesundheits-Dashboard')),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final values = {
            'Aktive Medikation': _count(
              db.select(
                'SELECT COUNT(*) AS count FROM medications WHERE active = 1',
              ),
            ),
            'Offene Termine': _count(
              db.select(
                "SELECT COUNT(*) AS count FROM appointments WHERE status != 'Erledigt'",
              ),
            ),
            'Vitalwerte': _count(
              db.select('''
                SELECT
                  (SELECT COUNT(*) FROM blood_pressure_logs) +
                  (SELECT COUNT(*) FROM weight_logs) AS count
                '''),
            ),
            'Ungelesen': _count(
              db.select(
                'SELECT COUNT(*) AS count FROM notifications WHERE read = 0',
              ),
            ),
          };
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _DashboardCard(
                title: 'Aktive Medikation',
                value: values['Aktive Medikation']!,
                icon: GpIcons.medication,
                colors: GpColors.blue,
              ),
              _DashboardCard(
                title: 'Offene Termine',
                value: values['Offene Termine']!,
                icon: GpIcons.appointments,
                colors: GpColors.orange,
              ),
              _DashboardCard(
                title: 'Vitalwerte',
                value: values['Vitalwerte']!,
                icon: GpIcons.bloodPressure,
                colors: GpColors.green,
              ),
              _DashboardCard(
                title: 'Ungelesen',
                value: values['Ungelesen']!,
                icon: Icons.notifications_active_outlined,
                colors: GpColors.purplePink,
              ),
            ],
          );
        },
      ),
    );
  }

  int _count(List<Map<String, Object?>> rows) => rows.first['count'] as int;
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
  });

  final String title;
  final int value;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 34),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(title, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
