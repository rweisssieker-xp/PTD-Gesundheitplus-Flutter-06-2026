import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_database_error.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../../medication/data/medication_repository.dart';
import '../../medication/domain/medication.dart';
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
    return GpScreen(
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
        error: (error, stackTrace) => GpDatabaseError(
          error: error,
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
        data: (db) {
          final safetyRepo = MedicationSafetyRepository(db);
          final medicationRepo = MedicationRepository(db);
          return FutureBuilder<List<Object>>(
            key: ValueKey(_reload),
            future: Future.wait([
              safetyRepo.listGuidance(),
              medicationRepo.listActive(),
            ]),
            builder: (context, snapshot) {
              final guidance = snapshot.data == null
                  ? <MedicationInteractionGuidance>[]
                  : snapshot.data![0] as List<MedicationInteractionGuidance>;
              final medications = snapshot.data == null
                  ? <Medication>[]
                  : snapshot.data![1] as List<Medication>;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                children: [
                  const _PageHeader(),
                  const SizedBox(height: 16),
                  const _SafetyFirstCard(),
                  const SizedBox(height: 12),
                  const _CheckedScopeCard(),
                  if (medications.length < 2) ...[
                    const SizedBox(height: 12),
                    _MedicationCountHint(count: medications.length),
                  ],
                  const SizedBox(height: 16),
                  _LocalCheckerCard(
                    medicationCount: medications.length,
                    onOpenChecker: () =>
                        context.go('/medication/interaction-checker'),
                  ),
                  const SizedBox(height: 16),
                  if (medications.isNotEmpty)
                    _ActiveMedicationList(medications: medications),
                  if (medications.isNotEmpty) const SizedBox(height: 16),
                  _GuidanceSection(guidance: guidance),
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

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(GpIcons.interactions, color: GpColors.emergencyRed, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Medikations-Wechselwirkungen',
                style: TextStyle(
                  color: GpColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          'Lokale Prüfung Ihrer aktiven Medikamente auf gefährliche Kombinationen',
          style: TextStyle(color: GpColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _SafetyFirstCard extends StatelessWidget {
  const _SafetyFirstCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBFDBFE), width: 2),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sicherheit zuerst',
                    style: TextStyle(
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Die native App prüft aktive Medikamente lokal und speichert Ergebnisse auf diesem Gerät.',
                    style: TextStyle(color: Color(0xFF1E40AF)),
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

class _CheckedScopeCard extends StatelessWidget {
  const _CheckedScopeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFFDE68A), width: 2),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_outlined, color: Color(0xFFD97706)),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Was wird geprüft?',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Kritische Wechselwirkungen, wichtige Kombinationen, moderate Vorsichtshinweise und Dosierungsrisiken.',
                    style: TextStyle(color: Color(0xFF92400E)),
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

class _MedicationCountHint extends StatelessWidget {
  const _MedicationCountHint({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final medicationText = count == 1
        ? '1 aktives Medikament'
        : '$count aktive Medikamente';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: GpColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hinweis',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sie haben aktuell $medicationText. Für eine Wechselwirkungsprüfung benötigen Sie mindestens 2 aktive Medikamente.',
                    style: const TextStyle(color: GpColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/medication'),
                    icon: const Icon(Icons.medication_outlined),
                    label: const Text('Medikamente verwalten'),
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

class _LocalCheckerCard extends StatelessWidget {
  const _LocalCheckerCard({
    required this.medicationCount,
    required this.onOpenChecker,
  });

  final int medicationCount;
  final VoidCallback onOpenChecker;

  @override
  Widget build(BuildContext context) {
    final ready = medicationCount >= 2;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  ready ? Icons.verified_user_outlined : Icons.lock_clock,
                  color: ready
                      ? const Color(0xFF16A34A)
                      : GpColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ready
                        ? 'Lokaler Checker bereit'
                        : 'Mehr aktive Medikamente nötig',
                    style: const TextStyle(
                      color: GpColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _Badge(label: '$medicationCount aktiv'),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Der Checker nutzt die lokal gespeicherte Medikamentenliste und die lokale Kontextfreigabe.',
              style: TextStyle(color: GpColors.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onOpenChecker,
              icon: const Icon(GpIcons.interactions),
              label: const Text('Lokalen Check öffnen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveMedicationList extends StatelessWidget {
  const _ActiveMedicationList({required this.medications});

  final List<Medication> medications;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ihre aktiven Medikamente (${medications.length})',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...medications.map(
              (medication) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GpColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            [
                              medication.dosage,
                              medication.frequency,
                            ].whereType<String>().join(' • '),
                            style: const TextStyle(
                              color: GpColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidanceSection extends StatelessWidget {
  const _GuidanceSection({required this.guidance});

  final List<MedicationInteractionGuidance> guidance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokale Interaktionshinweise',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (guidance.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text('Noch keine lokalen Interaktionshinweise'),
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
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
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
