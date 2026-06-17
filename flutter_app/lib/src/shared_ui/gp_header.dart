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
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 48, child: leading),
                      const Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Gesundheit Plus',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: GpColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Ihre digitale Gesundheitsakte',
                              style: TextStyle(
                                fontSize: 12,
                                color: GpColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: actions.isEmpty ? 48 : actions.length * 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              key: const Key('gp-header-red-border'),
              height: 4,
              color: GpColors.emergencyRed,
            ),
          ],
        ),
      ),
    );
  }
}
