import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_language.dart';
import '../core/localization/app_language_controller.dart';
import 'gp_colors.dart';
import 'gp_icons.dart';

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
                      Padding(
                        padding: EdgeInsets.only(
                          left: leading == null ? 0 : 112,
                          right: actions.isEmpty ? 0 : actions.length * 48,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Gesundheit Plus',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: GpColors.textPrimary,
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 260,
                                ),
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
                        ),
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
          Icon(GpIcons.shield, size: 12, color: Color(0xFF15803D)),
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

class GpLanguageButton extends ConsumerWidget {
  const GpLanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Sprache',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Consumer(
          builder: (context, ref, _) {
            final selected =
                ref.watch(appLanguageControllerProvider).valueOrNull ??
                AppLanguage.de;
            return SafeArea(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    const ListTile(
                      leading: Icon(Icons.language_outlined),
                      title: Text('Sprache'),
                      subtitle: Text('Lokale Anzeigeoptionen'),
                    ),
                    for (final language in AppLanguage.values)
                      _LanguageOption(
                        language: language,
                        selected: language == selected,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      icon: const Icon(GpIcons.language),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.language, this.selected = false});

  final AppLanguage language;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => ListTile(
        leading: selected
            ? const Icon(Icons.check_circle, color: GpColors.emergencyRed)
            : const SizedBox(width: 24),
        title: Text('${language.flag} ${language.label}'),
        onTap: () async {
          final navigator = Navigator.of(context);
          await ref
              .read(appLanguageControllerProvider.notifier)
              .setLanguage(language);
          navigator.pop();
        },
      ),
    );
  }
}
