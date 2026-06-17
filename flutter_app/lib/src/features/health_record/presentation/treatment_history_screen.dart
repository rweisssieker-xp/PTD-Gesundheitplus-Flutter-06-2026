import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../../../shared_ui/gp_voice_navigation.dart';
import '../data/health_record_repository.dart';
import '../domain/health_record.dart';

class TreatmentHistoryScreen extends ConsumerStatefulWidget {
  const TreatmentHistoryScreen({super.key});

  @override
  ConsumerState<TreatmentHistoryScreen> createState() =>
      _TreatmentHistoryScreenState();
}

class _TreatmentHistoryScreenState
    extends ConsumerState<TreatmentHistoryScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openEditor(HealthRecordRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Behandlung'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = HealthRecordRepository(db);
          return FutureBuilder<List<TreatmentRecord>>(
            key: ValueKey(_reload),
            future: repo.listTreatments(),
            builder: (context, snapshot) {
              final records = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: GpColors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(
                            GpIcons.treatmentHistory,
                            color: Colors.white,
                            size: 46,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Behandlungen',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '${records.length} Eintraege',
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
                  ),
                  const SizedBox(height: 12),
                  GpVoiceNavigation(content: _treatmentVoiceContent(records)),
                  const SizedBox(height: 16),
                  if (records.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('Noch keine Behandlungen')),
                      ),
                    )
                  else
                    ...records.map(
                      (record) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(GpIcons.treatmentHistory),
                          title: Text(record.title),
                          subtitle: Text(
                            '${_date(record.treatedAt)}'
                            '${record.provider == null ? '' : ' • ${record.provider}'}'
                            '${record.outcome == null ? '' : ' • ${record.outcome}'}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Loeschen',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await repo.deleteTreatment(record.id);
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
      builder: (context) => _TreatmentEditor(repo: repo),
    );
    if (saved == true) setState(() => _reload++);
  }
}

String _treatmentVoiceContent(List<TreatmentRecord> records) {
  if (records.isEmpty) {
    return 'Behandlungshistorie. Es sind noch keine Behandlungen gespeichert.';
  }
  final details = records
      .take(8)
      .map(
        (record) =>
            '${record.title} am ${_date(record.treatedAt)}'
            '${record.provider == null ? '' : ' bei ${record.provider}'}'
            '${record.outcome == null ? '' : ', Ergebnis: ${record.outcome}'}',
      )
      .join('. ');
  return 'Behandlungshistorie. ${records.length} Behandlungen gespeichert. $details.';
}

class _TreatmentEditor extends StatefulWidget {
  const _TreatmentEditor({required this.repo});

  final HealthRecordRepository repo;

  @override
  State<_TreatmentEditor> createState() => _TreatmentEditorState();
}

class _TreatmentEditorState extends State<_TreatmentEditor> {
  final _title = TextEditingController();
  final _provider = TextEditingController();
  final _specialty = TextEditingController();
  final _outcome = TextEditingController();

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
              'Behandlung erfassen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titel *'),
            ),
            TextField(
              controller: _provider,
              decoration: const InputDecoration(labelText: 'Arzt / Praxis'),
            ),
            TextField(
              controller: _specialty,
              decoration: const InputDecoration(labelText: 'Fachrichtung'),
            ),
            TextField(
              controller: _outcome,
              decoration: const InputDecoration(labelText: 'Ergebnis'),
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
    await widget.repo.addTreatment(
      title: title,
      provider: _emptyToNull(_provider.text),
      specialty: _emptyToNull(_specialty.text),
      outcome: _emptyToNull(_outcome.text),
    );
    if (mounted) Navigator.pop(context, true);
  }
}

String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
