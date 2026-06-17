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
                    style: FilledButton.styleFrom(
                      backgroundColor: GpColors.emergencyRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {},
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
                      onTap: () {},
                    ),
                    GpActionTile(
                      label: 'Scan',
                      icon: GpIcons.scan,
                      colors: GpColors.indigo,
                      onTap: () {},
                    ),
                    GpActionTile(
                      label: 'Tagesplan',
                      icon: GpIcons.dailyPlan,
                      colors: GpColors.orange,
                      onTap: () {},
                    ),
                    GpActionTile(
                      label: 'KI-Chat',
                      icon: GpIcons.chat,
                      colors: GpColors.purplePink,
                      onTap: () {},
                    ),
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
