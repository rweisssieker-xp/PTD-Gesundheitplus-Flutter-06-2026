import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'gp_colors.dart';

class GpFooter extends StatelessWidget {
  const GpFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: GpColors.border, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GradientFooterButton(
                    onTap: () => context.go('/onboarding'),
                    child: const SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Demo / Onboarding starten',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _FooterLink(
                        label: 'Datenschutz',
                        onTap: () => context.go('/privacy'),
                      ),
                      const Text(
                        '•',
                        style: TextStyle(
                          color: GpColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      _FooterLink(
                        label: 'Speicher-Modus',
                        icon: Icons.shield_outlined,
                        onTap: () => context.go('/privacy/storage'),
                      ),
                      const Text(
                        '•',
                        style: TextStyle(
                          color: GpColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        'Kontakt',
                        style: TextStyle(
                          color: GpColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Eine Initiative für Ihre Gesundheit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GpColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: GpColors.textSecondary),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: const TextStyle(
                color: GpColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientFooterButton extends StatelessWidget {
  const _GradientFooterButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: GpColors.blueIndigo),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}
