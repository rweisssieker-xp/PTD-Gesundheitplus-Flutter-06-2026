import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../../../shared_ui/gp_voice_navigation.dart';
import '../data/prevention_repository.dart';
import '../domain/prevention.dart';

class VaccinationScreen extends ConsumerStatefulWidget {
  const VaccinationScreen({super.key});

  @override
  ConsumerState<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends ConsumerState<VaccinationScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openEditor(PreventionRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Impfung'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = PreventionRepository(db);
          return FutureBuilder<List<VaccinationRecord>>(
            key: ValueKey(_reload),
            future: repo.listVaccinations(),
            builder: (context, snapshot) {
              final records = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PreventionHeader(
                    title: 'Digitaler Impfpass',
                    value: '${records.length}',
                    label: 'Eintraege',
                    icon: GpIcons.vaccination,
                  ),
                  const SizedBox(height: 12),
                  GpVoiceNavigation(content: _vaccinationVoiceContent(records)),
                  const SizedBox(height: 16),
                  if (records.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('Noch keine Impfungen')),
                      ),
                    )
                  else
                    ...records.map(
                      (record) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            GpIcons.vaccination,
                            color: record.boosterDue
                                ? GpColors.emergencyRed
                                : GpColors.blue.first,
                          ),
                          title: Text(record.vaccineName),
                          subtitle: Text(
                            '${_date(record.vaccinatedAt)}${record.targetDisease == null ? '' : ' • ${record.targetDisease}'}'
                            '${record.nextDueAt == null ? '' : ' • Auffrischung ${_date(record.nextDueAt!)}'}',
                          ),
                          trailing: record.boosterDue
                              ? const Icon(Icons.notification_important)
                              : null,
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

  Future<void> _openEditor(PreventionRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VaccinationEditor(repo: repo),
    );
    if (saved == true) setState(() => _reload++);
  }
}

String _vaccinationVoiceContent(List<VaccinationRecord> records) {
  if (records.isEmpty) {
    return 'Impfpass. Es sind noch keine Impfungen gespeichert.';
  }
  final due = records.where((record) => record.boosterDue).toList();
  final dueText = due.isEmpty
      ? 'Keine fälligen Auffrischungen markiert.'
      : '${due.length} Auffrischungen sind fällig: ${due.map((record) => record.vaccineName).join(', ')}.';
  final details = records
      .take(8)
      .map(
        (record) =>
            '${record.vaccineName} am ${_date(record.vaccinatedAt)}'
            '${record.targetDisease == null ? '' : ', Schutz gegen ${record.targetDisease}'}',
      )
      .join('. ');
  return 'Impfpass. ${records.length} Impfungen gespeichert. $dueText $details.';
}

class _VaccinationEditor extends StatefulWidget {
  const _VaccinationEditor({required this.repo});

  final PreventionRepository repo;

  @override
  State<_VaccinationEditor> createState() => _VaccinationEditorState();
}

class _VaccinationEditorState extends State<_VaccinationEditor> {
  final _vaccine = TextEditingController();
  final _disease = TextEditingController();
  final _doctor = TextEditingController();
  final _nextDueMonths = TextEditingController();

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
              'Impfung erfassen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _vaccine,
              decoration: const InputDecoration(labelText: 'Impfstoff *'),
            ),
            TextField(
              controller: _disease,
              decoration: const InputDecoration(labelText: 'Schutz gegen'),
            ),
            TextField(
              controller: _doctor,
              decoration: const InputDecoration(labelText: 'Arzt / Praxis'),
            ),
            TextField(
              controller: _nextDueMonths,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Auffrischung in Monaten',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final vaccine = _vaccine.text.trim();
    if (vaccine.isEmpty) return;
    final months = int.tryParse(_nextDueMonths.text);
    final now = DateTime.now();
    await widget.repo.addVaccination(
      vaccineName: vaccine,
      targetDisease: _emptyToNull(_disease.text),
      vaccinatedAt: now,
      nextDueAt: months == null
          ? null
          : DateTime(now.year, now.month + months, now.day),
      doctorName: _emptyToNull(_doctor.text),
    );
    if (mounted) Navigator.pop(context, true);
  }
}

class _PreventionHeader extends StatelessWidget {
  const _PreventionHeader({
    required this.title,
    required this.value,
    required this.label,
    required this.icon,
  });

  final String title;
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: GpColors.blue),
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
                  '$value $label',
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

String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
