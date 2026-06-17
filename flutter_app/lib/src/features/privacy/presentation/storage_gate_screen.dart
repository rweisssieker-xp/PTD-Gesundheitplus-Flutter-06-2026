import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../features/dashboard/presentation/dashboard_screen.dart';
import '../../../shared_ui/gp_colors.dart';
import '../data/storage_mode_repository.dart';

class StorageGateScreen extends ConsumerStatefulWidget {
  const StorageGateScreen({super.key});

  @override
  ConsumerState<StorageGateScreen> createState() => _StorageGateScreenState();
}

class _StorageGateScreenState extends ConsumerState<StorageGateScreen> {
  var _refresh = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return dbAsync.when(
      loading: () => const _StorageGateScaffold(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _StorageGateScaffold(
        child: Center(child: Text('Datenbankfehler: $error')),
      ),
      data: (db) {
        final repo = StorageModeRepository(db);
        if (repo.isLocalModeSelected()) {
          return const DashboardScreen();
        }
        return _StorageModeChoice(
          key: ValueKey(_refresh),
          onSelectLocal: () async {
            await repo.selectLocalMode();
            if (!mounted) return;
            setState(() => _refresh++);
          },
        );
      },
    );
  }
}

class _StorageModeChoice extends StatelessWidget {
  const _StorageModeChoice({super.key, required this.onSelectLocal});

  final Future<void> Function() onSelectLocal;

  @override
  Widget build(BuildContext context) {
    return _StorageGateScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          const Text(
            'Gesundheit Plus',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GpColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ersteinrichtung der Datenspeicherung',
            textAlign: TextAlign.center,
            style: TextStyle(color: GpColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 18),
          const Icon(
            Icons.shield_outlined,
            color: GpColors.emergencyRed,
            size: 44,
          ),
          const SizedBox(height: 18),
          const Text(
            'Wo sollen Ihre Daten gespeichert werden?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GpColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Diese Entscheidung können Sie später in den Einstellungen ändern.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GpColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          _ModeCard(
            borderColor: const Color(0xFF86EFAC),
            iconColor: const Color(0xFF16A34A),
            iconBackground: const Color(0xFFDCFCE7),
            icon: Icons.phone_android_outlined,
            title: 'Nur auf diesem Gerät',
            titleColor: const Color(0xFF166534),
            subtitle: 'Maximaler Datenschutz',
            subtitleColor: const Color(0xFF16A34A),
            featureIconColor: const Color(0xFF22C55E),
            features: const [
              'Daten verlassen nie Ihr Gerät',
              'Kein Server-Zugriff auf Gesundheitsdaten',
              'Funktioniert komplett offline',
            ],
            warning:
                'Bei Geräteverlust oder App-Deinstallation gehen Daten verloren. KI-Features haben eingeschränkten Zugriff.',
            buttonLabel: 'Lokal speichern wählen',
            buttonIcon: Icons.phone_android_outlined,
            buttonColors: const [Color(0xFF16A34A), Color(0xFF16A34A)],
            onPressed: onSelectLocal,
          ),
          const SizedBox(height: 18),
          _ModeCard(
            borderColor: const Color(0xFFBFDBFE),
            iconColor: const Color(0xFF2563EB),
            iconBackground: const Color(0xFFDBEAFE),
            icon: Icons.cloud_outlined,
            title: 'Cloud-Synchronisation',
            titleColor: const Color(0xFF1E40AF),
            subtitle: 'Volle Funktionalität',
            subtitleColor: const Color(0xFF2563EB),
            featureIconColor: const Color(0xFF3B82F6),
            features: const [
              'Auf allen Geräten verfügbar',
              'KI-Coach & alle Features voll verfügbar',
              'Automatisches Backup',
              'DSGVO-konform, Server in Deutschland',
            ],
            buttonLabel: 'Cloud-Sync wählen',
            buttonIcon: Icons.cloud_outlined,
            buttonColors: const [Color(0xFF2563EB), Color(0xFF4F46E5)],
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Diese native App speichert Gesundheitsdaten ausschließlich lokal.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StorageGateScaffold extends StatelessWidget {
  const _StorageGateScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GpColors.redSurface, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.borderColor,
    required this.iconColor,
    required this.iconBackground,
    required this.icon,
    required this.title,
    required this.titleColor,
    required this.subtitle,
    required this.subtitleColor,
    required this.featureIconColor,
    required this.features,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.buttonColors,
    required this.onPressed,
    this.warning,
  });

  final Color borderColor;
  final Color iconColor;
  final Color iconBackground;
  final IconData icon;
  final String title;
  final Color titleColor;
  final String subtitle;
  final Color subtitleColor;
  final Color featureIconColor;
  final List<String> features;
  final String buttonLabel;
  final IconData buttonIcon;
  final List<Color> buttonColors;
  final VoidCallback onPressed;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final feature in features)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: featureIconColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          color: GpColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (warning != null) ...[
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    '⚠ $warning',
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _GradientChoiceButton(
              label: buttonLabel,
              icon: buttonIcon,
              colors: buttonColors,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientChoiceButton extends StatelessWidget {
  const _GradientChoiceButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
