import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/notifications/native_notification_service.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../../../shared_ui/gp_voice_navigation.dart';
import '../../health_record/data/health_record_repository.dart';
import '../../health_record/domain/health_record.dart';
import '../data/medication_repository.dart';
import '../domain/medication.dart';
import '../domain/medication_text_parser.dart';

class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({super.key});

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen> {
  bool _showInactive = false;
  bool _showVoiceInput = false;
  int _reload = 0;
  final _notifications = NativeNotificationService();
  final _assistantText = TextEditingController();
  MedicationTextSuggestion? _assistantSuggestion;
  String? _assistantError;

  @override
  void dispose() {
    _assistantText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = MedicationRepository(db);
          final healthRepo = HealthRecordRepository(db);
          return FutureBuilder<_MedicationScreenData>(
            key: ValueKey(_reload),
            future: _loadMedicationScreenData(repo, healthRepo),
            builder: (context, snapshot) {
              final screenData = snapshot.data ?? _MedicationScreenData.empty();
              final medications = screenData.medications;
              final activeCount = medications.where((med) => med.active).length;
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
                children: [
                  const _MedicationPageTitle(),
                  const SizedBox(height: 20),
                  _AllergyInteractionCheckCard(
                    checkResult: screenData.allergyCheck,
                    onCheck: () =>
                        context.go('/medication/interaction-checker'),
                  ),
                  const SizedBox(height: 16),
                  _MedicationSummary(activeCount: activeCount),
                  const SizedBox(height: 14),
                  GpVoiceNavigation(
                    content: _medicationVoiceContent(medications),
                  ),
                  const SizedBox(height: 14),
                  _MedicationActionRow(
                    showInactive: _showInactive,
                    onInactiveChanged: (value) =>
                        setState(() => _showInactive = value),
                    onVoiceTap: () =>
                        setState(() => _showVoiceInput = !_showVoiceInput),
                    onAddTap: () => _openEditor(repo),
                  ),
                  if (_showVoiceInput) ...[
                    const SizedBox(height: 12),
                    _MedicationTextAssistantCard(
                      controller: _assistantText,
                      suggestion: _assistantSuggestion,
                      error: _assistantError,
                      onParse: _parseAssistantText,
                      onSave: _assistantSuggestion?.isComplete == true
                          ? () => _saveAssistantSuggestion(repo)
                          : null,
                    ),
                  ],
                  const SizedBox(height: 14),
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

  void _parseAssistantText() {
    final input = _assistantText.text.trim();
    if (input.isEmpty) {
      setState(() {
        _assistantSuggestion = null;
        _assistantError = 'Bitte beschreiben Sie das Medikament zuerst.';
      });
      return;
    }
    final suggestion = const MedicationTextParser().parse(input);
    setState(() {
      _assistantSuggestion = suggestion;
      _assistantError = suggestion.isComplete
          ? null
          : 'Fehlt noch: ${suggestion.missingFields.join(', ')}';
    });
  }

  Future<void> _saveAssistantSuggestion(MedicationRepository repo) async {
    final suggestion = _assistantSuggestion;
    if (suggestion == null || !suggestion.isComplete) {
      _parseAssistantText();
      return;
    }
    final medication = Medication(
      id: const Uuid().v4(),
      name: suggestion.name!.trim(),
      dosage: suggestion.dosage!.trim(),
      frequency: suggestion.frequency!.trim(),
      schedule: suggestion.reminderTimes.isEmpty
          ? suggestion.frequency!.trim()
          : 'Erinnerung ${suggestion.reminderTimes.join(', ')}',
      startDate: DateTime.now(),
      endDate: null,
      prescribedBy: suggestion.prescribedBy,
      reason: suggestion.reason,
      reminderEnabled: suggestion.reminderTimes.isNotEmpty,
      reminderTimes: suggestion.reminderTimes.isEmpty
          ? const ['08:00']
          : suggestion.reminderTimes,
      supplyDurationDays: null,
      refillReminderDays: 7,
      notes: 'Aus lokaler Texteingabe erstellt: ${suggestion.originalText}',
      active: true,
    );
    await repo.save(medication);
    try {
      await _scheduleMedication(medication);
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
    if (!mounted) return;
    _assistantText.clear();
    setState(() {
      _assistantSuggestion = null;
      _assistantError = null;
      _reload++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medikament aus Texteingabe gespeichert.')),
    );
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

  Future<_MedicationScreenData> _loadMedicationScreenData(
    MedicationRepository medicationRepo,
    HealthRecordRepository healthRepo,
  ) async {
    final results = await Future.wait<Object>([
      medicationRepo.list(includeInactive: _showInactive),
      healthRepo.checkMedicationAllergies(),
    ]);
    return _MedicationScreenData(
      medications: results[0] as List<Medication>,
      allergyCheck: results[1] as AllergyMedicationCheckResult,
    );
  }
}

class _MedicationScreenData {
  const _MedicationScreenData({
    required this.medications,
    required this.allergyCheck,
  });

  factory _MedicationScreenData.empty() => _MedicationScreenData(
    medications: const [],
    allergyCheck: AllergyMedicationCheckResult(
      activeMedicationCount: 0,
      medicationAllergyCount: 0,
      conflicts: const [],
    ),
  );

  final List<Medication> medications;
  final AllergyMedicationCheckResult allergyCheck;
}

String _medicationVoiceContent(List<Medication> medications) {
  if (medications.isEmpty) {
    return 'Medikation. Es sind noch keine Medikamente gespeichert.';
  }
  final active = medications.where((medication) => medication.active).toList();
  final reminderCount = active
      .where((medication) => medication.reminderEnabled)
      .length;
  final buffer = StringBuffer(
    'Medikation. ${medications.length} Medikamente gespeichert. ${active.length} aktive Medikamente. ',
  );
  if (reminderCount > 0) {
    buffer.write('$reminderCount Medikamente mit Erinnerung. ');
  }
  for (final medication in active.take(8)) {
    buffer
      ..write(medication.name)
      ..write(', ')
      ..write(medication.dosage)
      ..write(', ')
      ..write(medication.frequency)
      ..write('. ');
    final reason = medication.reason;
    if (reason != null && reason.trim().isNotEmpty) {
      buffer
        ..write('Grund: ')
        ..write(reason.trim())
        ..write('. ');
    }
  }
  return buffer.toString();
}

class _MedicationPageTitle extends StatelessWidget {
  const _MedicationPageTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medikation',
          style: TextStyle(
            color: GpColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Ihr Medikamentenplan',
          style: TextStyle(color: GpColors.textSecondary, fontSize: 16),
        ),
      ],
    );
  }
}

class _AllergyInteractionCheckCard extends StatelessWidget {
  const _AllergyInteractionCheckCard({
    required this.checkResult,
    required this.onCheck,
  });

  final AllergyMedicationCheckResult checkResult;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Allergie &\nWechselwirkungs-\nCheck',
                    style: TextStyle(
                      color: GpColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: onCheck,
                  icon: const Icon(Icons.health_and_safety_outlined, size: 16),
                  label: const Text(
                    'Jetzt prüfen',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${checkResult.activeMedicationCount} Medikament(e) · '
              '${checkResult.medicationAllergyCount} Medikamenten-Allergie(n)',
              style: const TextStyle(
                color: GpColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Klicken Sie auf „Jetzt prüfen“, um Ihre Medikamente automatisch auf Wechselwirkungen und Allergie-Konflikte zu analysieren.',
              style: TextStyle(color: GpColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationActionRow extends StatelessWidget {
  const _MedicationActionRow({
    required this.showInactive,
    required this.onInactiveChanged,
    required this.onVoiceTap,
    required this.onAddTap,
  });

  final bool showInactive;
  final ValueChanged<bool> onInactiveChanged;
  final VoidCallback onVoiceTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(value: showInactive, onChanged: onInactiveChanged),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Abgesetzte\nanzeigen',
            style: TextStyle(fontWeight: FontWeight.w800, height: 1.15),
          ),
        ),
        const SizedBox(width: 8),
        _DarkActionButton(
          label: 'Sprache',
          icon: Icons.mic_none_outlined,
          colors: const [Color(0xFFA855F7), Color(0xFF9333EA)],
          onTap: onVoiceTap,
        ),
        const SizedBox(width: 8),
        _DarkActionButton(
          label: 'Hinzufügen',
          icon: Icons.add,
          colors: const [Color(0xFF111111), Color(0xFF111111)],
          onTap: onAddTap,
        ),
      ],
    );
  }
}

class _DarkActionButton extends StatelessWidget {
  const _DarkActionButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: SizedBox(
            height: 40,
            width: 112,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
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

class _MedicationTextAssistantCard extends StatelessWidget {
  const _MedicationTextAssistantCard({
    required this.controller,
    required this.suggestion,
    required this.error,
    required this.onParse,
    required this.onSave,
  });

  final TextEditingController controller;
  final MedicationTextSuggestion? suggestion;
  final String? error;
  final VoidCallback onParse;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFFED7AA), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.mic_outlined, color: Color(0xFFEA580C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokale Medikamenteneingabe',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Beschreiben Sie Name, Dosierung und Einnahme wie gesprochen. Die App erkennt die Daten direkt auf dem Gerät.',
              style: TextStyle(color: GpColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Medikament beschreiben',
                hintText:
                    'Ramipril 5mg einmal taeglich morgens wegen Blutdruck',
                border: OutlineInputBorder(),
              ),
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 12),
              _MedicationSuggestionPreview(suggestion: suggestion!),
            ],
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: const TextStyle(
                  color: GpColors.emergencyRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onParse,
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    label: const Text('Erkennen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.check),
                    label: const Text('Speichern'),
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

class _MedicationSuggestionPreview extends StatelessWidget {
  const _MedicationSuggestionPreview({required this.suggestion});

  final MedicationTextSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: GpColors.border, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Erkannter Vorschlag',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _SuggestionLine(
              icon: Icons.medication_outlined,
              label: suggestion.name ?? 'Medikament fehlt',
            ),
            _SuggestionLine(
              icon: Icons.science_outlined,
              label: suggestion.dosage ?? 'Dosierung fehlt',
            ),
            _SuggestionLine(
              icon: Icons.repeat_outlined,
              label: suggestion.frequency ?? 'Haeufigkeit fehlt',
            ),
            if ((suggestion.reason ?? '').isNotEmpty)
              _SuggestionLine(
                icon: Icons.info_outline,
                label: suggestion.reason!,
              ),
            if ((suggestion.prescribedBy ?? '').isNotEmpty)
              _SuggestionLine(
                icon: Icons.person_outline,
                label: suggestion.prescribedBy!,
              ),
            if (suggestion.reminderTimes.isNotEmpty)
              _SuggestionLine(
                icon: Icons.notifications_outlined,
                label: 'Erinnerung ${suggestion.reminderTimes.join(', ')}',
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionLine extends StatelessWidget {
  const _SuggestionLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 17, color: GpColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(label)),
        ],
      ),
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
      child: SizedBox(
        height: 112,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aktive Medikamente',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 26),
              child: Icon(
                GpIcons.medication,
                color: Color(0xFFFFEDD5),
                size: 66,
              ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: GpColors.border, width: 2),
      ),
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
  final _supplyDurationDays = TextEditingController();
  final _refillReminderDays = TextEditingController(text: '7');
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
      _supplyDurationDays.text = med.supplyDurationDays?.toString() ?? '';
      _refillReminderDays.text = med.refillReminderDays?.toString() ?? '7';
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
              controller: _supplyDurationDays,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Vorrat reicht fuer Tage',
              ),
            ),
            TextField(
              controller: _refillReminderDays,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rezept-Erinnerung Tage vorher',
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
      startDate: existing?.startDate ?? DateTime.now(),
      endDate: existing?.endDate,
      prescribedBy: _prescribedBy.text.trim(),
      reason: _reason.text.trim(),
      reminderEnabled: _reminderEnabled,
      reminderTimes: _reminderTimes.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
      supplyDurationDays: int.tryParse(_supplyDurationDays.text),
      refillReminderDays: int.tryParse(_refillReminderDays.text) ?? 7,
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
