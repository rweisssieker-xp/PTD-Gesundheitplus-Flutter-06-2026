import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/notifications/native_notification_service.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../data/medication_repository.dart';
import '../domain/medication.dart';

class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({super.key});

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen> {
  bool _showInactive = false;
  int _reload = 0;
  final _notifications = NativeNotificationService();

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Medikation')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openEditor(MedicationRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Hinzufuegen'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = MedicationRepository(db);
          return FutureBuilder<List<Medication>>(
            key: ValueKey(_reload),
            future: repo.list(includeInactive: _showInactive),
            builder: (context, snapshot) {
              final medications = snapshot.data ?? [];
              final activeCount = medications.where((med) => med.active).length;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _MedicationSummary(activeCount: activeCount),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _showInactive,
                    onChanged: (value) => setState(() {
                      _showInactive = value;
                    }),
                    title: const Text('Abgesetzte anzeigen'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (medications.isEmpty)
                    _EmptyMedicationState(onAdd: () => _openEditor(repo))
                  else
                    ...medications.map(
                      (medication) => _MedicationCard(
                        medication: medication,
                        onEdit: () => _openEditor(repo, medication: medication),
                        onToggleActive: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final updated = medication.copyWith(
                            active: !medication.active,
                          );
                          await repo.save(updated);
                          try {
                            if (updated.active) {
                              await _scheduleMedication(updated);
                            } else {
                              await _cancelMedication(medication);
                            }
                          } catch (_) {
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Medikament aktualisiert, Benachrichtigung konnte nicht angepasst werden.',
                                  ),
                                ),
                              );
                            }
                          }
                          _refresh();
                        },
                        onDelete: () async {
                          await _cancelMedication(medication);
                          await repo.delete(medication.id);
                          _refresh();
                        },
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

  Future<void> _openEditor(
    MedicationRepository repo, {
    Medication? medication,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MedicationEditor(
        repo: repo,
        medication: medication,
        scheduleMedication: _scheduleMedication,
        cancelMedication: _cancelMedication,
      ),
    );
    if (saved == true) _refresh();
  }

  void _refresh() {
    setState(() {
      _reload++;
    });
  }

  Future<void> _scheduleMedication(Medication medication) async {
    if (!medication.active || !medication.reminderEnabled) return;
    final reminders = NotificationScheduler().medicationReminders(
      medicationId: medication.id,
      medicationName: medication.name,
      reminderTimes: medication.reminderTimes,
      now: DateTime.now(),
    );
    for (final reminder in reminders) {
      await _notifications.scheduleDailyReminder(
        reminder,
        body: [medication.dosage, medication.frequency]
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .join(' • '),
      );
    }
  }

  Future<void> _cancelMedication(Medication medication) {
    return _notifications.cancelMedicationReminders(
      medicationId: medication.id,
      reminderTimes: medication.reminderTimes,
    );
  }
}

class _MedicationSummary extends StatelessWidget {
  const _MedicationSummary({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: GpColors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(GpIcons.medication, color: Colors.white, size: 46),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aktive Medikamente',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '$activeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
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

class _EmptyMedicationState extends StatelessWidget {
  const _EmptyMedicationState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(GpIcons.medication, color: Colors.black26, size: 52),
            const SizedBox(height: 12),
            const Text('Noch keine Medikamente hinzugefuegt'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Erstes Medikament hinzufuegen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final Medication medication;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: GpColors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(GpIcons.medication, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        [medication.dosage, medication.frequency]
                            .whereType<String>()
                            .where((v) => v.isNotEmpty)
                            .join(' • '),
                        style: const TextStyle(color: GpColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'toggle') onToggleActive();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Bearbeiten'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        medication.active ? 'Absetzen' : 'Aktivieren',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Loeschen'),
                    ),
                  ],
                ),
              ],
            ),
            if ((medication.schedule ?? '').isNotEmpty)
              _DetailLine(icon: Icons.schedule, text: medication.schedule!),
            if ((medication.reason ?? '').isNotEmpty)
              _DetailLine(icon: Icons.info_outline, text: medication.reason!),
            if (medication.reminderEnabled &&
                medication.reminderTimes.isNotEmpty)
              _DetailLine(
                icon: Icons.notifications_outlined,
                text: 'Erinnerungen: ${medication.reminderTimes.join(', ')}',
              ),
            if (!medication.active)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Chip(label: Text('Abgesetzt')),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: GpColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: GpColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationEditor extends StatefulWidget {
  const _MedicationEditor({
    required this.repo,
    required this.scheduleMedication,
    required this.cancelMedication,
    this.medication,
  });

  final MedicationRepository repo;
  final Future<void> Function(Medication medication) scheduleMedication;
  final Future<void> Function(Medication medication) cancelMedication;
  final Medication? medication;

  @override
  State<_MedicationEditor> createState() => _MedicationEditorState();
}

class _MedicationEditorState extends State<_MedicationEditor> {
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _frequency = TextEditingController(text: '1x taeglich');
  final _schedule = TextEditingController();
  final _reason = TextEditingController();
  final _prescribedBy = TextEditingController();
  final _notes = TextEditingController();
  final _reminderTimes = TextEditingController(text: '08:00');
  bool _active = true;
  bool _reminderEnabled = true;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    if (med != null) {
      _name.text = med.name;
      _dosage.text = med.dosage ?? '';
      _frequency.text = med.frequency ?? '1x taeglich';
      _schedule.text = med.schedule ?? '';
      _reason.text = med.reason ?? '';
      _prescribedBy.text = med.prescribedBy ?? '';
      _notes.text = med.notes ?? '';
      _reminderTimes.text = med.reminderTimes.join(', ');
      _active = med.active;
      _reminderEnabled = med.reminderEnabled;
    }
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.medication == null
                  ? 'Neues Medikament'
                  : 'Medikament bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Medikamentenname *',
              ),
            ),
            TextField(
              controller: _dosage,
              decoration: const InputDecoration(labelText: 'Dosierung *'),
            ),
            TextField(
              controller: _frequency,
              decoration: const InputDecoration(labelText: 'Haeufigkeit *'),
            ),
            TextField(
              controller: _schedule,
              decoration: const InputDecoration(labelText: 'Einnahmezeiten'),
            ),
            TextField(
              controller: _prescribedBy,
              decoration: const InputDecoration(labelText: 'Verschrieben von'),
            ),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Grund / Indikation',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
              title: const Text('Erinnerungen aktivieren'),
            ),
            TextField(
              controller: _reminderTimes,
              decoration: const InputDecoration(
                labelText: 'Erinnerungszeiten, kommagetrennt',
              ),
            ),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notizen'),
              maxLines: 2,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              title: const Text('Aktiv in Einnahme'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty ||
        _dosage.text.trim().isEmpty ||
        _frequency.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Name, Dosierung und Haeufigkeit eingeben'),
        ),
      );
      return;
    }
    final existing = widget.medication;
    final medication = Medication(
      id: existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      dosage: _dosage.text.trim(),
      frequency: _frequency.text.trim(),
      schedule: _schedule.text.trim(),
      startDate: existing?.startDate,
      endDate: existing?.endDate,
      prescribedBy: _prescribedBy.text.trim(),
      reason: _reason.text.trim(),
      reminderEnabled: _reminderEnabled,
      reminderTimes: _reminderTimes.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
      refillReminderDays: existing?.refillReminderDays ?? 7,
      notes: _notes.text.trim(),
      active: _active,
    );
    await widget.repo.save(medication);
    try {
      if (existing != null) {
        await widget.cancelMedication(existing);
      }
      await widget.cancelMedication(medication);
      await widget.scheduleMedication(medication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Medikament gespeichert, Benachrichtigung konnte nicht geplant werden.',
            ),
          ),
        );
      }
    }
    if (mounted) Navigator.pop(context, true);
  }
}
