import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/health_record_repository.dart';
import '../domain/anamnesis_payload_builder.dart';
import '../domain/health_record.dart';

class AnamnesisScreen extends ConsumerStatefulWidget {
  const AnamnesisScreen({super.key});

  @override
  ConsumerState<AnamnesisScreen> createState() => _AnamnesisScreenState();
}

class _AnamnesisScreenState extends ConsumerState<AnamnesisScreen> {
  int _reload = 0;
  bool _showQrCode = false;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = HealthRecordRepository(db);
          return FutureBuilder<List<MedicalHistoryEntry>>(
            key: ValueKey(_reload),
            future: repo.listHistoryEntries(),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
                children: [
                  _PageTitleAction(
                    title: 'Krankengeschichte',
                    subtitle: 'Ihre medizinische Anamnese',
                    actionLabel: 'Bearbeiten',
                    icon: Icons.description_outlined,
                    onPressed: () => _openEditor(repo),
                  ),
                  const SizedBox(height: 16),
                  _AnamnesisQrCard(
                    entries: entries,
                    visible: _showQrCode,
                    onToggle: () => setState(() => _showQrCode = !_showQrCode),
                  ),
                  const SizedBox(height: 16),
                  if (entries.isEmpty)
                    const _LifestyleCard()
                  else
                    ...entries.map(
                      (entry) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            GpIcons.anamnesis,
                            color: entry.active
                                ? GpColors.emergencyRed
                                : GpColors.textSecondary,
                          ),
                          title: Text(entry.title),
                          subtitle: Text(
                            '${entry.category}${entry.details == null ? '' : ' • ${entry.details}'}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Loeschen',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await repo.deleteHistoryEntry(entry.id);
                              if (mounted) setState(() => _reload++);
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(HealthRecordRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AnamnesisEditor(repo: repo),
    );
    if (saved == true) setState(() => _reload++);
  }
}

class _PageTitleAction extends StatelessWidget {
  const _PageTitleAction({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: GpColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: GpColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF111111),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _AnamnesisQrCard extends StatelessWidget {
  const _AnamnesisQrCard({
    required this.entries,
    required this.visible,
    required this.onToggle,
  });

  final List<MedicalHistoryEntry> entries;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final payload = AnamnesisPayloadBuilder().build(entries);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2, color: GpColors.emergencyRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QR-Code für Weitergabe',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onToggle,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              icon: const Icon(Icons.qr_code_2),
              label: Text(
                visible ? 'QR-Code ausblenden' : 'QR-Code generieren',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ärzte können Ihre Anamnese mit dem QR-Code einlesen. Teilen Sie ihn nur mit medizinischem Fachpersonal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: GpColors.textSecondary, fontSize: 12),
            ),
            if (visible) ...[
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: GpColors.border, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(data: payload, size: 210),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LifestyleCard extends StatelessWidget {
  const _LifestyleCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lebensstil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 24),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Rauchen: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: 'Nichtraucher'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnamnesisEditor extends StatefulWidget {
  const _AnamnesisEditor({required this.repo});

  final HealthRecordRepository repo;

  @override
  State<_AnamnesisEditor> createState() => _AnamnesisEditorState();
}

class _AnamnesisEditorState extends State<_AnamnesisEditor> {
  final _category = TextEditingController(text: 'Vorerkrankung');
  final _title = TextEditingController();
  final _details = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Anamnese erfassen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Kategorie'),
            ),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titel *'),
            ),
            TextField(
              controller: _details,
              decoration: const InputDecoration(labelText: 'Details'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    await widget.repo.addHistoryEntry(
      category: _emptyToNull(_category.text) ?? 'Anamnese',
      title: title,
      details: _emptyToNull(_details.text),
    );
    if (mounted) Navigator.pop(context, true);
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
