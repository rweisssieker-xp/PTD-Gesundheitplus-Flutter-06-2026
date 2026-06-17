import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_icons.dart';
import '../data/vitals_repository.dart';
import '../domain/vitals.dart';
import 'blood_pressure_screen.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Gewicht')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openEditor(VitalsRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Messung'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = VitalsRepository(db);
          return FutureBuilder<List<WeightLog>>(
            key: ValueKey(_reload),
            future: repo.listWeight(),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  VitalsHeader(
                    title: 'Gewicht & BMI',
                    value: logs.isEmpty
                        ? '-'
                        : '${logs.first.weightKg.toStringAsFixed(1)} kg',
                    icon: GpIcons.weight,
                  ),
                  const SizedBox(height: 16),
                  if (logs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('Noch keine Gewichtswerte')),
                      ),
                    )
                  else
                    ...logs.map(
                      (log) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(
                            GpIcons.weight,
                            color: Colors.deepPurple,
                          ),
                          title: Text('${log.weightKg.toStringAsFixed(1)} kg'),
                          subtitle: Text(
                            '${log.measuredAt.day}.${log.measuredAt.month}.${log.measuredAt.year}${log.bmi == null ? '' : ' • BMI ${log.bmi!.toStringAsFixed(1)}'}',
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

  Future<void> _openEditor(VitalsRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _WeightEditor(repo: repo),
    );
    if (saved == true) setState(() => _reload++);
  }
}

class _WeightEditor extends StatefulWidget {
  const _WeightEditor({required this.repo});

  final VitalsRepository repo;

  @override
  State<_WeightEditor> createState() => _WeightEditorState();
}

class _WeightEditorState extends State<_WeightEditor> {
  final _weight = TextEditingController();
  final _height = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Gewicht erfassen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
            controller: _weight,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Gewicht kg *'),
          ),
          TextField(
            controller: _height,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Groesse cm'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Speichern')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weight.text.replaceAll(',', '.'));
    if (weight == null) return;
    await widget.repo.addWeight(
      weightKg: weight,
      heightCm: double.tryParse(_height.text.replaceAll(',', '.')),
    );
    if (mounted) Navigator.pop(context, true);
  }
}
