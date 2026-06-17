import 'package:flutter/material.dart';

import 'gp_colors.dart';

class GpHeader extends StatelessWidget {
  const GpHeader({
    super.key,
    this.leading,
    this.actions = const [],
    this.showLocalBadge = true,
  });

  final Widget? leading;
  final List<Widget> actions;
  final bool showLocalBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GpColors.surface,
      elevation: 4,
      shadowColor: const Color(0x22000000),
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
                    vertical: 16,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (leading != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(width: 104, child: leading),
                        ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Gesundheit Plus',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: GpColors.textPrimary,
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Ihre digitale Gesundheitsakte',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: GpColors.textSecondary,
                                    ),
                                  ),
                                  if (showLocalBadge) ...[
                                    const SizedBox(width: 8),
                                    const _LocalBadge(),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (actions.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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

class _LocalBadge extends StatelessWidget {
  const _LocalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 12, color: Color(0xFF15803D)),
          SizedBox(width: 3),
          Text(
            'Lokal',
            style: TextStyle(
              color: Color(0xFF15803D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
