import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'gp_colors.dart';
import 'gp_footer.dart';
import 'gp_header.dart';
import 'gp_icons.dart';

class GpScreen extends StatelessWidget {
  const GpScreen({
    super.key,
    this.child,
    this.body,
    this.floatingActionButton,
    this.actions,
    this.showNavigation = true,
  }) : assert(child != null || body != null, 'child or body is required');

  final Widget? child;
  final Widget? body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          GpHeader(
            leading: showNavigation ? const _GpBackHomeButtons() : null,
            actions:
                actions ??
                const [
                  GpLanguageButton(),
                  _GpNotificationButton(),
                  _GpSettingsButton(),
                ],
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [GpColors.redSurface, Colors.white],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: body ?? child!,
                ),
              ),
            ),
          ),
          const GpFooter(),
        ],
      ),
    );
  }
}

class _GpBackHomeButtons extends StatelessWidget {
  const _GpBackHomeButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GpHeaderButton(
          tooltip: 'Zurueck',
          icon: GpIcons.back,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        const SizedBox(width: 8),
        _GpHeaderButton(
          tooltip: 'Startseite',
          icon: GpIcons.home,
          onPressed: () => context.go('/'),
        ),
      ],
    );
  }
}

class _GpNotificationButton extends StatelessWidget {
  const _GpNotificationButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Benachrichtigungen',
      onPressed: () => context.go('/notifications'),
      icon: const Icon(GpIcons.notifications),
    );
  }
}

class _GpSettingsButton extends StatelessWidget {
  const _GpSettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Datenschutz',
      onPressed: () => context.go('/privacy'),
      icon: const Icon(GpIcons.settings),
    );
  }
}

class _GpHeaderButton extends StatelessWidget {
  const _GpHeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: GpColors.textPrimary,
          side: const BorderSide(color: GpColors.border, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Tooltip(message: tooltip, child: Icon(icon, size: 24)),
      ),
    );
  }
}
