import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../data/health_record_repository.dart';
import '../domain/health_record.dart';

class AnamnesisScreen extends ConsumerStatefulWidget {
  const AnamnesisScreen({super.key});

  @override
  ConsumerState<AnamnesisScreen> createState() => _AnamnesisScreenState();
}

class _AnamnesisScreenState extends ConsumerState<AnamnesisScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Anamnese')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openEditor(HealthRecordRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Eintrag'),
      ),
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
                padding: const EdgeInsets.all(16),
                children: [
                  _HealthRecordHeader(count: entries.length, title: 'Anamnese'),
                  const SizedBox(height: 16),
                  if (entries.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('Noch keine Anamnese')),
                      ),
                    )
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

class _HealthRecordHeader extends StatelessWidget {
  const _HealthRecordHeader({required this.count, required this.title});

  final int count;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: GpColors.indigo),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(GpIcons.anamnesis, color: Colors.white, size: 46),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70)),
                Text(
                  '$count Eintraege',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
