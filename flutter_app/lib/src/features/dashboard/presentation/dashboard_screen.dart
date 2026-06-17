import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          GpHeader(
            actions: [
              IconButton(
                tooltip: 'Benachrichtigungen',
                onPressed: () => context.go('/notifications'),
                icon: const Icon(Icons.notifications_none),
              ),
              IconButton(
                tooltip: 'Datenschutz',
                onPressed: () => context.go('/privacy'),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(
                  height: 64,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: GpColors.emergencyRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => context.go('/emergency/offline'),
                    icon: const Icon(GpIcons.emergency),
                    label: const Text(
                      'SOS Notfall',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.86,
                  children: [
                    GpActionTile(
                      label: 'KI-Coach',
                      icon: GpIcons.aiCoach,
                      colors: GpColors.purplePink,
                      onTap: () => context.go('/ai/coach'),
                    ),
                    GpActionTile(
                      label: 'Scan',
                      icon: GpIcons.scan,
                      colors: GpColors.indigo,
                      onTap: () => context.go('/documents/scan'),
                    ),
                    GpActionTile(
                      label: 'Tagesplan',
                      icon: GpIcons.dailyPlan,
                      colors: GpColors.orange,
                      onTap: () => context.go('/medication/daily-plan'),
                    ),
                    GpActionTile(
                      label: 'KI-Chat',
                      icon: GpIcons.chat,
                      colors: GpColors.purplePink,
                      onTap: () => context.go('/ai/coach'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.go('/medication'),
                  icon: const Icon(GpIcons.medication),
                  label: const Text('Medikation verwalten'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go('/appointments'),
                  icon: const Icon(GpIcons.appointments),
                  label: const Text('Termine verwalten'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go('/health/professionals'),
                  icon: const Icon(GpIcons.healthcare),
                  label: const Text('Heilberufe verwalten'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go('/vitals/blood-pressure'),
                  icon: const Icon(GpIcons.bloodPressure),
                  label: const Text('Blutdruck erfassen'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go('/vitals/weight'),
                  icon: const Icon(GpIcons.weight),
                  label: const Text('Gewicht erfassen'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go('/prevention/vaccination'),
                  icon: const Icon(GpIcons.vaccination),
                  label: const Text('Impfpass verwalten'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go('/prevention/care'),
                  icon: const Icon(GpIcons.prevention),
                  label: const Text('Vorsorge planen'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go('/emergency/setup'),
                  icon: const Icon(GpIcons.emergency),
                  label: const Text('Notfallkontakte verwalten'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go('/privacy/storage'),
                  icon: const Icon(Icons.storage_outlined),
                  label: const Text('Lokalen Speicher anzeigen'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
