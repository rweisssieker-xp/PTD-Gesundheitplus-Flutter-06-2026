import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/vitals_repository.dart';
import '../domain/vitals.dart';

class BloodPressureScreen extends ConsumerStatefulWidget {
  const BloodPressureScreen({super.key});

  @override
  ConsumerState<BloodPressureScreen> createState() =>
      _BloodPressureScreenState();
}

class _BloodPressureScreenState extends ConsumerState<BloodPressureScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
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
          return FutureBuilder<List<BloodPressureLog>>(
            key: ValueKey(_reload),
            future: repo.listBloodPressure(),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  VitalsHeader(
                    title: 'Blutdruck & Puls',
                    value: logs.isEmpty
                        ? '-'
                        : '${logs.first.systolic}/${logs.first.diastolic}',
                    icon: GpIcons.bloodPressure,
                  ),
                  const SizedBox(height: 16),
                  if (logs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('Noch keine Blutdruckwerte')),
                      ),
                    )
                  else
                    ...logs.map(
                      (log) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(
                            GpIcons.bloodPressure,
                            color: GpColors.emergencyRed,
                          ),
                          title: Text('${log.systolic}/${log.diastolic} mmHg'),
                          subtitle: Text(
                            '${log.measuredAt.day}.${log.measuredAt.month}.${log.measuredAt.year}${log.pulse == null ? '' : ' • Puls ${log.pulse}'}',
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
      builder: (context) => _BloodPressureEditor(repo: repo),
    );
    if (saved == true) setState(() => _reload++);
  }
}

class _BloodPressureEditor extends StatefulWidget {
  const _BloodPressureEditor({required this.repo});

  final VitalsRepository repo;

  @override
  State<_BloodPressureEditor> createState() => _BloodPressureEditorState();
}

class _BloodPressureEditorState extends State<_BloodPressureEditor> {
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _pulse = TextEditingController();

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
            'Blutdruck erfassen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
            controller: _systolic,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Systolisch *'),
          ),
          TextField(
            controller: _diastolic,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Diastolisch *'),
          ),
          TextField(
            controller: _pulse,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Puls'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Speichern')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final systolic = int.tryParse(_systolic.text);
    final diastolic = int.tryParse(_diastolic.text);
    if (systolic == null || diastolic == null) return;
    await widget.repo.addBloodPressure(
      systolic: systolic,
      diastolic: diastolic,
      pulse: int.tryParse(_pulse.text),
    );
    if (mounted) Navigator.pop(context, true);
  }
}

class VitalsHeader extends StatelessWidget {
  const VitalsHeader({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), GpColors.emergencyRed],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 46),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70)),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
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
