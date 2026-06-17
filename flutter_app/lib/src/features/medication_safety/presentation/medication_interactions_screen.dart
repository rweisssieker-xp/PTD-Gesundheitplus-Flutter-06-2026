import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../data/medication_safety_repository.dart';
import '../domain/medication_safety.dart';

class MedicationInteractionsScreen extends ConsumerStatefulWidget {
  const MedicationInteractionsScreen({super.key});

  @override
  ConsumerState<MedicationInteractionsScreen> createState() =>
      _MedicationInteractionsScreenState();
}

class _MedicationInteractionsScreenState
    extends ConsumerState<MedicationInteractionsScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Medikations-Interaktionen')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () =>
                  _openEditor(MedicationSafetyRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Hinweis'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = MedicationSafetyRepository(db);
          return FutureBuilder<List<MedicationInteractionGuidance>>(
            key: ValueKey(_reload),
            future: repo.listGuidance(),
            builder: (context, snapshot) {
              final guidance = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (guidance.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: Text(
                            'Noch keine lokalen Interaktionshinweise',
                          ),
                        ),
                      ),
                    )
                  else
                    ...guidance.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            GpIcons.interactions,
                            color: item.severity == 'hoch'
                                ? GpColors.emergencyRed
                                : GpColors.textSecondary,
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.severity} • ${item.description}'
                            '${item.action == null ? '' : ' • ${item.action}'}',
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

  Future<void> _openEditor(MedicationSafetyRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _GuidanceEditor(repo: repo),
    );
    if (saved == true) setState(() => _reload++);
  }
}

class _GuidanceEditor extends StatefulWidget {
  const _GuidanceEditor({required this.repo});

  final MedicationSafetyRepository repo;

  @override
  State<_GuidanceEditor> createState() => _GuidanceEditorState();
}

class _GuidanceEditorState extends State<_GuidanceEditor> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _action = TextEditingController();
  String _severity = 'mittel';

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
              'Interaktionshinweis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: 'Schweregrad'),
              items: const [
                DropdownMenuItem(value: 'niedrig', child: Text('niedrig')),
                DropdownMenuItem(value: 'mittel', child: Text('mittel')),
                DropdownMenuItem(value: 'hoch', child: Text('hoch')),
              ],
              onChanged: (value) =>
                  setState(() => _severity = value ?? 'mittel'),
            ),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titel *'),
            ),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Beschreibung *'),
            ),
            TextField(
              controller: _action,
              decoration: const InputDecoration(labelText: 'Aktion'),
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
    final description = _description.text.trim();
    if (title.isEmpty || description.isEmpty) return;
    await widget.repo.addGuidance(
      title: title,
      severity: _severity,
      description: description,
      action: _emptyToNull(_action.text),
    );
    if (mounted) Navigator.pop(context, true);
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
