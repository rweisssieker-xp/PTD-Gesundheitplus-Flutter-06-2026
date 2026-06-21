import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_database_error.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../../../shared_ui/gp_voice_navigation.dart';
import '../data/health_record_repository.dart';
import '../domain/allergy_text_parser.dart';
import '../domain/health_record.dart';

class AllergiesScreen extends ConsumerStatefulWidget {
  const AllergiesScreen({super.key});

  @override
  ConsumerState<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends ConsumerState<AllergiesScreen> {
  int _reload = 0;
  final _assistantText = TextEditingController();
  AllergyTextSuggestion? _assistantSuggestion;
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openEditor(HealthRecordRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Allergie'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => GpDatabaseError(
          error: error,
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
        data: (db) {
          final repo = HealthRecordRepository(db);
          return FutureBuilder<List<AllergyRecord>>(
            key: ValueKey(_reload),
            future: repo.listAllergies(),
            builder: (context, snapshot) {
              final allergies = snapshot.data ?? [];
              final severe = allergies
                  .where(
                    (allergy) =>
                        allergy.severity == 'Schwer' ||
                        allergy.severity == 'Lebensbedrohlich',
                  )
                  .toList();
              final grouped = _groupByCategory(allergies);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _AllergySummary(count: allergies.length),
                  const SizedBox(height: 12),
                  GpVoiceNavigation(content: _allergyVoiceContent(allergies)),
                  const SizedBox(height: 12),
                  _AllergyTextAssistantCard(
                    controller: _assistantText,
                    suggestion: _assistantSuggestion,
                    error: _assistantError,
                    onParse: _parseAssistantText,
                    onSave: _assistantSuggestion?.isComplete == true
                        ? () => _saveAssistantSuggestion(repo)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<AllergyMedicationCheckResult>(
                    future: repo.checkMedicationAllergies(),
                    builder: (context, checkSnapshot) {
                      final result = checkSnapshot.data;
                      if (result == null) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Allergie-Check wird vorbereitet...',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return _AllergyMedicationCheckCard(result: result);
                    },
                  ),
                  if (severe.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _SevereAllergyWarning(allergies: severe),
                  ],
                  const SizedBox(height: 16),
                  if (allergies.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            const Icon(
                              GpIcons.allergies,
                              color: GpColors.textSecondary,
                              size: 42,
                            ),
                            const SizedBox(height: 12),
                            const Text('Noch keine Allergien eingetragen'),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => _openEditor(repo),
                              icon: const Icon(Icons.add),
                              label: const Text('Erste Allergie hinzufügen'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...grouped.entries.expand(
                      (entry) => [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                          child: Text(
                            '${entry.key} (${entry.value.length})',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        ...entry.value.map(
                          (allergy) => _AllergyCard(
                            allergy: allergy,
                            onEdit: () => _openEditor(repo, allergy: allergy),
                            onDelete: () async {
                              await repo.deleteAllergy(allergy.id);
                              if (mounted) setState(() => _reload++);
                            },
                          ),
                        ),
                      ],
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
    HealthRecordRepository repo, {
    AllergyRecord? allergy,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AllergyEditor(repo: repo, allergy: allergy),
    );
    if (saved == true) setState(() => _reload++);
  }

  void _parseAssistantText() {
    final input = _assistantText.text.trim();
    if (input.isEmpty) {
      setState(() {
        _assistantSuggestion = null;
        _assistantError = 'Bitte beschreiben Sie die Allergie zuerst.';
      });
      return;
    }
    final suggestion = const AllergyTextParser().parse(input);
    setState(() {
      _assistantSuggestion = suggestion;
      _assistantError = suggestion.isComplete
          ? null
          : 'Fehlt noch: ${suggestion.missingFields.join(', ')}';
    });
  }

  Future<void> _saveAssistantSuggestion(HealthRecordRepository repo) async {
    final suggestion = _assistantSuggestion;
    if (suggestion == null || !suggestion.isComplete) {
      _parseAssistantText();
      return;
    }
    await repo.addAllergy(
      substance: suggestion.substance!.trim(),
      category: suggestion.category,
      severity: suggestion.severity,
      reaction: suggestion.reaction,
      notes: 'Aus lokaler Texteingabe erstellt: ${suggestion.originalText}',
    );
    if (!mounted) return;
    _assistantText.clear();
    setState(() {
      _assistantSuggestion = null;
      _assistantError = null;
      _reload++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Allergie aus Texteingabe gespeichert.')),
    );
  }

  Map<String, List<AllergyRecord>> _groupByCategory(
    List<AllergyRecord> allergies,
  ) {
    final grouped = <String, List<AllergyRecord>>{};
    for (final allergy in allergies) {
      final category = allergy.category ?? 'Sonstiges';
      grouped.putIfAbsent(category, () => []).add(allergy);
    }
    return grouped;
  }
}

class _AllergyTextAssistantCard extends StatelessWidget {
  const _AllergyTextAssistantCard({
    required this.controller,
    required this.suggestion,
    required this.error,
    required this.onParse,
    required this.onSave,
  });

  final TextEditingController controller;
  final AllergyTextSuggestion? suggestion;
  final String? error;
  final VoidCallback onParse;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFEFCE8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFFEF08A), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.mic_outlined, color: Color(0xFFCA8A04)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokale Allergieeingabe',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Beschreiben Sie Allergen und Reaktion wie gesprochen. Die App erkennt Kategorie und Schweregrad direkt auf dem Gerät.',
              style: TextStyle(color: GpColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Allergie beschreiben',
                hintText:
                    'Allergisch gegen Penicillin mit Atemnot und Schwellung',
                border: OutlineInputBorder(),
              ),
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 12),
              _AllergySuggestionPreview(suggestion: suggestion!),
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

class _AllergySuggestionPreview extends StatelessWidget {
  const _AllergySuggestionPreview({required this.suggestion});

  final AllergyTextSuggestion suggestion;

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
              icon: Icons.warning_amber_outlined,
              label: suggestion.substance ?? 'Allergen fehlt',
            ),
            _SuggestionLine(
              icon: Icons.category_outlined,
              label: suggestion.category,
            ),
            _SuggestionLine(
              icon: Icons.report_problem_outlined,
              label: suggestion.severity,
            ),
            if ((suggestion.reaction ?? '').isNotEmpty)
              _SuggestionLine(
                icon: Icons.medical_information_outlined,
                label: suggestion.reaction!,
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

class _AllergyMedicationCheckCard extends StatefulWidget {
  const _AllergyMedicationCheckCard({required this.result});

  final AllergyMedicationCheckResult result;

  @override
  State<_AllergyMedicationCheckCard> createState() =>
      _AllergyMedicationCheckCardState();
}

class _AllergyMedicationCheckCardState
    extends State<_AllergyMedicationCheckCard> {
  var _expanded = true;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final color = result.hasConflicts
        ? GpColors.emergencyRed
        : GpColors.green.first;
    return Card(
      color: result.hasConflicts
          ? const Color(0xFFFFF7ED)
          : const Color(0xFFF0FDF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: result.hasConflicts
              ? const Color(0xFFFB923C)
              : const Color(0xFFBBF7D0),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: color),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Allergie & Medikamenten-Check',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: GpColors.textPrimary,
                    ),
                  ),
                ),
                if (result.hasConflicts)
                  IconButton(
                    tooltip: _expanded ? 'Einklappen' : 'Ausklappen',
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${result.activeMedicationCount} Medikament(e) • ${result.medicationAllergyCount} Medikamenten-Allergie(n)',
              style: const TextStyle(
                color: GpColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      result.hasConflicts
                          ? Icons.warning_amber_outlined
                          : Icons.check_circle_outline,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Risiko: ${result.overallRisk}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            result.summary,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (result.hasConflicts && _expanded) ...[
              const SizedBox(height: 10),
              for (final conflict in result.conflicts)
                _AllergyConflictTile(conflict: conflict),
            ],
            const SizedBox(height: 8),
            const Text(
              'Diese lokale Prüfung ersetzt keine ärztliche Beratung.',
              style: TextStyle(color: GpColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergyConflictTile extends StatelessWidget {
  const _AllergyConflictTile({required this.conflict});

  final AllergyMedicationConflict conflict;

  @override
  Widget build(BuildContext context) {
    final color = conflict.severity == 'Kontraindiziert'
        ? GpColors.emergencyRed
        : const Color(0xFFEA580C);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem_outlined, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${conflict.medicationName} ↔ ${conflict.allergen}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _Badge(text: conflict.severity, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            conflict.description,
            style: const TextStyle(color: GpColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            conflict.recommendation,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String _allergyVoiceContent(List<AllergyRecord> allergies) {
  if (allergies.isEmpty) {
    return 'Allergien. Es sind noch keine Allergien eingetragen.';
  }
  final severe = allergies
      .where(
        (allergy) =>
            allergy.severity == 'Schwer' ||
            allergy.severity == 'Lebensbedrohlich',
      )
      .toList();
  final severeText = severe.isEmpty
      ? 'Keine schweren Allergien markiert.'
      : 'Wichtig: ${severe.length} schwere Allergien: ${severe.map((allergy) => allergy.substance).join(', ')}.';
  final list = allergies
      .take(8)
      .map(
        (allergy) =>
            '${allergy.substance}, ${allergy.category ?? 'Sonstiges'}, Schweregrad ${allergy.severity ?? 'nicht angegeben'}',
      )
      .join('. ');
  return 'Allergien. ${allergies.length} Allergien gespeichert. $severeText $list.';
}

class _AllergySummary extends StatelessWidget {
  const _AllergySummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: GpColors.yellow),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(GpIcons.allergies, color: Colors.white, size: 48),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bekannte Allergien',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
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

class _SevereAllergyWarning extends StatelessWidget {
  const _SevereAllergyWarning({required this.allergies});

  final List<AllergyRecord> allergies;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFEF2F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFFCA5A5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: GpColors.emergencyRed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WICHTIG: Schwere Allergien',
                    style: TextStyle(
                      color: Color(0xFF7F1D1D),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...allergies.map(
                    (allergy) => Text(
                      '${allergy.substance} (${allergy.severity})',
                      style: const TextStyle(color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergyCard extends StatelessWidget {
  const _AllergyCard({
    required this.allergy,
    required this.onEdit,
    required this.onDelete,
  });

  final AllergyRecord allergy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: GpColors.border, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: GpColors.yellow),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(GpIcons.allergies, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allergy.substance,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Badge(text: allergy.category ?? 'Sonstiges'),
                          _Badge(
                            text: allergy.severity ?? 'Mittel',
                            color: _severityColor(allergy.severity),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                    PopupMenuItem(value: 'delete', child: Text('Löschen')),
                  ],
                ),
              ],
            ),
            if (allergy.reaction != null) ...[
              const SizedBox(height: 12),
              Text('Reaktion', style: Theme.of(context).textTheme.labelLarge),
              Text(allergy.reaction!),
            ],
            if (allergy.diagnosedBy != null || allergy.diagnosedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                [
                  if (allergy.diagnosedBy != null)
                    'Festgestellt von ${allergy.diagnosedBy}',
                  if (allergy.diagnosedAt != null)
                    'am ${_date(allergy.diagnosedAt!)}',
                ].join(' '),
                style: const TextStyle(color: GpColors.textSecondary),
              ),
            ],
            if (allergy.notes != null) ...[
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFCE8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFEF08A)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(allergy.notes!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _severityColor(String? severity) {
    return switch (severity) {
      'Leicht' => const Color(0xFFCA8A04),
      'Mittel' => const Color(0xFFEA580C),
      'Schwer' => GpColors.emergencyRed,
      'Lebensbedrohlich' => const Color(0xFF7F1D1D),
      _ => GpColors.textSecondary,
    };
  }
}

class _AllergyEditor extends StatefulWidget {
  const _AllergyEditor({required this.repo, this.allergy});

  final HealthRecordRepository repo;
  final AllergyRecord? allergy;

  @override
  State<_AllergyEditor> createState() => _AllergyEditorState();
}

class _AllergyEditorState extends State<_AllergyEditor> {
  static const _categories = [
    'Medikament',
    'Nahrungsmittel',
    'Pollen',
    'Tierhaare',
    'Hausstaubmilben',
    'Insektengift',
    'Kontaktallergie',
    'Sonstiges',
  ];
  static const _severities = ['Leicht', 'Mittel', 'Schwer', 'Lebensbedrohlich'];

  late final TextEditingController _substance;
  late final TextEditingController _reaction;
  late final TextEditingController _diagnosedBy;
  late final TextEditingController _notes;
  late String _category;
  late String _severity;
  DateTime? _diagnosedAt;

  @override
  void initState() {
    super.initState();
    final allergy = widget.allergy;
    _substance = TextEditingController(text: allergy?.substance);
    _reaction = TextEditingController(text: allergy?.reaction);
    _diagnosedBy = TextEditingController(text: allergy?.diagnosedBy);
    _notes = TextEditingController(text: allergy?.notes);
    _category = allergy?.category ?? 'Medikament';
    _severity = allergy?.severity ?? 'Mittel';
    _diagnosedAt = allergy?.diagnosedAt;
  }

  @override
  void dispose() {
    _substance.dispose();
    _reaction.dispose();
    _diagnosedBy.dispose();
    _notes.dispose();
    super.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.allergy == null ? 'Neue Allergie' : 'Allergie bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _substance,
              decoration: const InputDecoration(
                labelText: 'Allergen / Unverträglichkeit *',
                hintText: 'z.B. Penicillin, Nüsse, Pollen',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategorie'),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: 'Schweregrad'),
              items: _severities
                  .map(
                    (severity) => DropdownMenuItem(
                      value: severity,
                      child: Text(severity),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _severity = value!),
            ),
            TextField(
              controller: _reaction,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reaktion',
                hintText: 'z.B. Hautausschlag, Atemnot, Schwellungen',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Festgestellt am'),
              subtitle: Text(
                _diagnosedAt == null ? 'Kein Datum' : _date(_diagnosedAt!),
              ),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  initialDate: _diagnosedAt ?? DateTime.now(),
                );
                if (picked != null) setState(() => _diagnosedAt = picked);
              },
            ),
            TextField(
              controller: _diagnosedBy,
              decoration: const InputDecoration(labelText: 'Festgestellt von'),
            ),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notizen'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final substance = _substance.text.trim();
    if (substance.isEmpty) return;
    final allergy = widget.allergy;
    if (allergy == null) {
      await widget.repo.addAllergy(
        substance: substance,
        category: _category,
        severity: _severity,
        reaction: _emptyToNull(_reaction.text),
        diagnosedAt: _diagnosedAt,
        diagnosedBy: _emptyToNull(_diagnosedBy.text),
        notes: _emptyToNull(_notes.text),
      );
    } else {
      await widget.repo.updateAllergy(
        id: allergy.id,
        substance: substance,
        category: _category,
        severity: _severity,
        reaction: _emptyToNull(_reaction.text),
        diagnosedAt: _diagnosedAt,
        diagnosedBy: _emptyToNull(_diagnosedBy.text),
        notes: _emptyToNull(_notes.text),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.color = GpColors.textSecondary});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
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
