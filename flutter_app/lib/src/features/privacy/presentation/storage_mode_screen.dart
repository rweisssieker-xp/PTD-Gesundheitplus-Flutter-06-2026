import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_database_error.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/local_privacy_repository.dart';
import '../data/storage_mode_repository.dart';

class StorageModeScreen extends ConsumerStatefulWidget {
  const StorageModeScreen({super.key});

  @override
  ConsumerState<StorageModeScreen> createState() => _StorageModeScreenState();
}

class _StorageModeScreenState extends ConsumerState<StorageModeScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => GpDatabaseError(
          error: error,
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
        data: (db) {
          final privacyRepo = LocalPrivacyRepository(db);
          final storageRepo = StorageModeRepository(db);
          return FutureBuilder<LocalPrivacySnapshot>(
            key: ValueKey(_reload),
            future: privacyRepo.snapshot(),
            builder: (context, snapshot) {
              final data = snapshot.data;
              final localSelected = storageRepo.isLocalModeSelected();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  const _Header(),
                  const SizedBox(height: 16),
                  _CurrentModeCard(
                    localSelected: localSelected,
                    totalRows: data?.totalRows ?? 0,
                  ),
                  const SizedBox(height: 16),
                  _SwitchModeCard(
                    localSelected: localSelected,
                    onSelectLocal: () async {
                      await storageRepo.selectLocalMode();
                      if (mounted) setState(() => _reload++);
                    },
                  ),
                  const SizedBox(height: 16),
                  _LocalDataManagementCard(
                    onBackup: () => context.go('/export'),
                    onClear: data == null
                        ? null
                        : () => _confirmClear(privacyRepo),
                  ),
                  const SizedBox(height: 16),
                  _ModeDifferenceCard(),
                  const SizedBox(height: 16),
                  _LocalCountsCard(snapshot: data),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(LocalPrivacyRepository repo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle lokalen Daten löschen?'),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden. Erstellen Sie vorher ein Backup, wenn Sie die Daten behalten möchten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GpColors.emergencyRed,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await repo.clearAllLocalData();
    if (!mounted) return;
    setState(() => _reload++);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lokale Daten wurden gelöscht.')),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(GpIcons.shield, color: GpColors.emergencyRed, size: 32),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Speicher-Modus',
                style: TextStyle(
                  color: GpColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Datenschutz & Datenspeicherung',
                style: TextStyle(color: GpColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentModeCard extends StatelessWidget {
  const _CurrentModeCard({
    required this.localSelected,
    required this.totalRows,
  });

  final bool localSelected;
  final int totalRows;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: localSelected ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: localSelected
              ? const Color(0xFF4ADE80)
              : const Color(0xFFFDE68A),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: localSelected
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFF7ED),
              child: Icon(
                localSelected
                    ? Icons.phone_android_outlined
                    : Icons.warning_amber_outlined,
                color: localSelected
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFCA8A04),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localSelected
                        ? 'Lokaler Modus aktiv'
                        : 'Lokaler Modus noch nicht bestätigt',
                    style: const TextStyle(
                      color: GpColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    localSelected
                        ? 'Daten nur auf diesem Gerät • $totalRows lokale Datensätze'
                        : 'Bitte lokalen Modus aktivieren, bevor Gesundheitsdaten genutzt werden.',
                    style: const TextStyle(
                      color: GpColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _ModeBadge(label: localSelected ? 'Lokal' : 'Offen'),
          ],
        ),
      ),
    );
  }
}

class _SwitchModeCard extends StatelessWidget {
  const _SwitchModeCard({
    required this.localSelected,
    required this.onSelectLocal,
  });

  final bool localSelected;
  final VoidCallback onSelectLocal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(icon: Icons.refresh, title: 'Modus wechseln'),
            const SizedBox(height: 12),
            const _WarningBox(
              text:
                  'Diese native Version speichert Gesundheitsdaten ausschließlich lokal. Cloud-Sync ist absichtlich deaktiviert.',
              color: Color(0xFF2563EB),
              background: Color(0xFFEFF6FF),
              border: Color(0xFFBFDBFE),
            ),
            const SizedBox(height: 12),
            if (localSelected)
              const _WarningBox(
                text:
                    'Beim Geräteverlust oder bei App-Deinstallation können lokale Daten verloren gehen. Erstellen Sie regelmäßig ein Backup.',
                color: Color(0xFFB45309),
                background: Color(0xFFFFFBEB),
                border: Color(0xFFFDE68A),
              )
            else
              OutlinedButton.icon(
                onPressed: onSelectLocal,
                icon: const Icon(Icons.phone_android_outlined),
                label: const Text('Lokalen Modus aktivieren'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LocalDataManagementCard extends StatelessWidget {
  const _LocalDataManagementCard({
    required this.onBackup,
    required this.onClear,
  });

  final VoidCallback onBackup;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(
              icon: Icons.download_outlined,
              title: 'Lokale Datenverwaltung',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onBackup,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Backup als JSON erstellen'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: GpColors.emergencyRed,
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 2),
              ),
              onPressed: onClear,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Alle lokalen Daten löschen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeDifferenceCard extends StatelessWidget {
  const _ModeDifferenceCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Color(0xFFF9FAFB),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unterschiede der Modi',
              style: TextStyle(
                color: GpColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            _ModeInfoLine(
              icon: Icons.phone_android_outlined,
              color: Color(0xFF16A34A),
              title: 'Lokal',
              body:
                  'Maximaler Datenschutz, kein Server-Zugriff, funktioniert offline, Backup manuell.',
            ),
            SizedBox(height: 10),
            _ModeInfoLine(
              icon: Icons.cloud_outlined,
              color: Color(0xFF2563EB),
              title: 'Cloud',
              body:
                  'In dieser nativen App nicht aktiv. Eine spätere Cloud-Funktion braucht Migration, Einwilligung und Serverbetrieb.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalCountsCard extends StatelessWidget {
  const _LocalCountsCard({required this.snapshot});

  final LocalPrivacySnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _CountRow(
        label: 'Gesundheitsdaten',
        value: _count([
          'medications',
          'medication_logs',
          'allergies',
          'medical_history_entries',
          'treatment_records',
          'blood_pressure_logs',
          'weight_logs',
          'vaccinations',
          'health_passes',
          'preventive_care_items',
        ]),
      ),
      _CountRow(
        label: 'Termine & Heilberufe',
        value: _count(['appointments', 'healthcare_professionals']),
      ),
      _CountRow(label: 'Dokumente', value: _count(['health_documents'])),
      _CountRow(
        label: 'Notfall & Kommunikation',
        value: _count([
          'emergency_contacts',
          'notifications',
          'communication_preferences',
        ]),
      ),
      _CountRow(
        label: 'Einstellungen & KI',
        value: _count([
          'local_profiles',
          'consent_settings',
          'app_preferences',
          'ai_coach_messages',
        ]),
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.storage_outlined,
              title: 'Lokaler Speicherinhalt',
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i < rows.length - 1) const Divider(height: 18),
            ],
          ],
        ),
      ),
    );
  }

  int _count(List<String> tables) {
    final counts = snapshot?.tableCounts;
    if (counts == null) return 0;
    return tables.fold<int>(0, (sum, table) => sum + (counts[table] ?? 0));
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            color: GpColors.textSecondary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: label == 'Lokal'
            ? const Color(0xFF16A34A)
            : const Color(0xFFCA8A04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: GpColors.textPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: GpColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({
    required this.text,
    required this.color,
    required this.background,
    required this.border,
  });

  final String text;
  final Color color;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ModeInfoLine extends StatelessWidget {
  const _ModeInfoLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    color: GpColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: body,
                  style: const TextStyle(color: GpColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
