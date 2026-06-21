import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../features/documents/data/document_repository.dart';
import '../../../features/documents/domain/health_document.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_database_error.dart';
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
  int _tab = 0;

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
        error: (error, stackTrace) => GpDatabaseError(
          error: error,
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
        data: (db) {
          final repo = PreventionRepository(db);
          final documentRepo = DocumentRepository(db);
          return FutureBuilder<_VaccinationDashboardData>(
            key: ValueKey(_reload),
            future: _loadDashboard(repo, documentRepo),
            builder: (context, snapshot) {
              final data = snapshot.data ?? _VaccinationDashboardData.empty();
              final records = data.vaccinations;
              final recommendations = data.recommendations;
              final passes = data.healthPasses;
              final boosters = records
                  .where((record) => record.nextDueAt != null)
                  .where((record) {
                    final months = _monthsUntil(record.nextDueAt!);
                    return months >= 0 && months <= 3 || record.boosterDue;
                  })
                  .toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                children: [
                  _VaccinationHeader(
                    vaccinationCount: records.length,
                    passCount: passes.length,
                  ),
                  const SizedBox(height: 12),
                  GpVoiceNavigation(content: _vaccinationVoiceContent(records)),
                  const SizedBox(height: 16),
                  if (recommendations.isNotEmpty) ...[
                    _VaccinationRecommendationsCard(
                      recommendations: recommendations.take(3).toList(),
                      onPlan: (recommendation) =>
                          _planVaccinationRecommendation(repo, recommendation),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (boosters.isNotEmpty) ...[
                    _BoosterCard(records: boosters),
                    const SizedBox(height: 16),
                  ],
                  _VaccinationStatsRow(
                    vaccinations: records,
                    passCount: passes.length,
                  ),
                  const SizedBox(height: 16),
                  _SegmentedTabs(
                    selected: _tab,
                    vaccinationCount: records.length,
                    passCount: passes.length,
                    onChanged: (value) => setState(() => _tab = value),
                  ),
                  const SizedBox(height: 12),
                  if (_tab == 0)
                    _VaccinationList(records: records)
                  else
                    _HealthPassList(documents: passes),
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

  Future<_VaccinationDashboardData> _loadDashboard(
    PreventionRepository repo,
    DocumentRepository documentRepo,
  ) async {
    final vaccinations = await repo.listVaccinations();
    final recommendations = await repo.generateRecommendations();
    final documents = await documentRepo.listDocuments();
    final healthPasses = documents.where(_isHealthPassDocument).toList();
    return _VaccinationDashboardData(
      vaccinations: vaccinations,
      recommendations: recommendations
          .where((item) => item.category == 'Impfung')
          .toList(),
      healthPasses: healthPasses,
    );
  }

  Future<void> _planVaccinationRecommendation(
    PreventionRepository repo,
    PreventionRecommendation recommendation,
  ) async {
    await repo.addPreventiveCare(
      title: recommendation.title,
      category: recommendation.category,
      dueAt: recommendation.dueAt,
      intervalMonths: recommendation.intervalMonths,
      doctorName: recommendation.doctorName,
      notes: recommendation.reason,
    );
    if (!mounted) return;
    setState(() => _reload++);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${recommendation.title} geplant.')));
  }
}

class _VaccinationDashboardData {
  const _VaccinationDashboardData({
    required this.vaccinations,
    required this.recommendations,
    required this.healthPasses,
  });

  factory _VaccinationDashboardData.empty() => const _VaccinationDashboardData(
    vaccinations: [],
    recommendations: [],
    healthPasses: [],
  );

  final List<VaccinationRecord> vaccinations;
  final List<PreventionRecommendation> recommendations;
  final List<HealthDocument> healthPasses;
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

class _VaccinationHeader extends StatelessWidget {
  const _VaccinationHeader({
    required this.vaccinationCount,
    required this.passCount,
  });

  final int vaccinationCount;
  final int passCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(GpIcons.vaccination, color: Color(0xFF4F46E5), size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Impfpass & Gesundheitspaesse',
                    style: TextStyle(
                      color: GpColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Ihre Impfungen und wichtigen Gesundheitsdokumente',
                    style: TextStyle(
                      color: GpColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(GpIcons.vaccination, color: Colors.white, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '$vaccinationCount Impfungen lokal gespeichert',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _WhiteBadge(label: '$passCount Paesse'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VaccinationRecommendationsCard extends StatelessWidget {
  const _VaccinationRecommendationsCard({
    required this.recommendations,
    required this.onPlan,
  });

  final List<PreventionRecommendation> recommendations;
  final ValueChanged<PreventionRecommendation> onPlan;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFAF5FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFD8B4FE), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: Color(0xFF7C3AED)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'KI-Impfempfehlungen',
                    style: TextStyle(
                      color: GpColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final recommendation in recommendations)
              _RecommendationCard(
                recommendation: recommendation,
                onPlan: () => onPlan(recommendation),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.onPlan,
  });

  final PreventionRecommendation recommendation;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final color = recommendation.isHighPriority
        ? GpColors.emergencyRed
        : const Color(0xFFF97316);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: recommendation.isHighPriority
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(GpIcons.vaccination, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: const TextStyle(
                        color: GpColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      recommendation.urgency == 'hoch'
                          ? 'Dringend'
                          : 'Empfohlen',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onPlan,
                icon: const Icon(Icons.add_task_outlined, size: 18),
                label: const Text('Planen'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.reason,
            style: const TextStyle(color: GpColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _BoosterCard extends StatelessWidget {
  const _BoosterCard({required this.records});

  final List<VaccinationRecord> records;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFFDE68A), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notification_important, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anstehende Auffrischungen',
                    style: TextStyle(
                      color: GpColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final record in records.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.vaccineName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      record.boosterDue ? 'faellig' : _date(record.nextDueAt!),
                      style: TextStyle(
                        color: record.boosterDue
                            ? GpColors.emergencyRed
                            : const Color(0xFFD97706),
                        fontWeight: FontWeight.w900,
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

class _VaccinationStatsRow extends StatelessWidget {
  const _VaccinationStatsRow({
    required this.vaccinations,
    required this.passCount,
  });

  final List<VaccinationRecord> vaccinations;
  final int passCount;

  @override
  Widget build(BuildContext context) {
    final activeReminders = vaccinations
        .where((record) => record.nextDueAt != null && !record.boosterDue)
        .length;
    final due = vaccinations.where((record) => record.boosterDue).length;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.notifications_active_outlined,
            value: '$activeReminders',
            label: 'Reminder',
            color: const Color(0xFF2563EB),
            background: const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.calendar_month_outlined,
            value: '$due',
            label: 'Faellig',
            color: const Color(0xFFD97706),
            background: const Color(0xFFFFF7ED),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.file_present_outlined,
            value: '$passCount',
            label: 'Paesse',
            color: const Color(0xFF16A34A),
            background: const Color(0xFFF0FDF4),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.selected,
    required this.vaccinationCount,
    required this.passCount,
    required this.onChanged,
  });

  final int selected;
  final int vaccinationCount;
  final int passCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(
          value: 0,
          icon: const Icon(GpIcons.vaccination),
          label: Text('Impfungen ($vaccinationCount)'),
        ),
        ButtonSegment(
          value: 1,
          icon: const Icon(Icons.file_present_outlined),
          label: Text('Paesse ($passCount)'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _VaccinationList extends StatelessWidget {
  const _VaccinationList({required this.records});

  final List<VaccinationRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyState(
        icon: GpIcons.vaccination,
        title: 'Noch keine Impfungen',
        body: 'Neue Impfungen werden lokal auf diesem Geraet gespeichert.',
      );
    }
    return Column(
      children: [
        for (final record in records)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: record.boosterDue
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFEFF6FF),
                    child: Icon(
                      GpIcons.vaccination,
                      color: record.boosterDue
                          ? GpColors.emergencyRed
                          : GpColors.blue.first,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.vaccineName,
                          style: const TextStyle(
                            color: GpColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          [
                            _date(record.vaccinatedAt),
                            record.targetDisease,
                            record.doctorName,
                          ].whereType<String>().join(' • '),
                          style: const TextStyle(
                            color: GpColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (record.batchNumber != null ||
                            record.nextDueAt != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (record.batchNumber != null)
                                _SoftBadge(
                                  label: 'Charge ${record.batchNumber}',
                                  color: const Color(0xFF4B5563),
                                  background: const Color(0xFFF3F4F6),
                                ),
                              if (record.nextDueAt != null)
                                _SoftBadge(
                                  label:
                                      'Auffrischung ${_date(record.nextDueAt!)}',
                                  color: record.boosterDue
                                      ? GpColors.emergencyRed
                                      : const Color(0xFF2563EB),
                                  background: record.boosterDue
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFEFF6FF),
                                ),
                            ],
                          ),
                        ],
                        if (record.notes != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            record.notes!,
                            style: const TextStyle(
                              color: GpColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (record.boosterDue)
                    const Icon(
                      Icons.notification_important,
                      color: GpColors.emergencyRed,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HealthPassList extends StatelessWidget {
  const _HealthPassList({required this.documents});

  final List<HealthDocument> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const _EmptyState(
        icon: Icons.file_present_outlined,
        title: 'Noch keine Gesundheitspaesse',
        body:
            'Implantatpaesse, Allergiepaesse oder aehnliche Dokumente koennen ueber den Dokumenten-Scan abgelegt werden.',
      );
    }
    return Column(
      children: [
        for (final document in documents)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(
                Icons.file_present_outlined,
                color: Color(0xFF16A34A),
              ),
              title: Text(document.title),
              subtitle: Text(
                '${document.category} • ${_date(document.capturedAt)}',
              ),
              trailing: document.encrypted
                  ? const Icon(Icons.lock_outline, color: Color(0xFF16A34A))
                  : null,
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, color: GpColors.textSecondary, size: 38),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: GpColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: GpColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteBadge extends StatelessWidget {
  const _WhiteBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

bool _isHealthPassDocument(HealthDocument document) {
  final text = '${document.title} ${document.category}'.toLowerCase();
  return text.contains('pass') ||
      text.contains('implantat') ||
      text.contains('allergie') ||
      text.contains('notfall') ||
      text.contains('ausweis');
}

int _monthsUntil(DateTime date) {
  final now = DateTime.now();
  return (date.year - now.year) * 12 + date.month - now.month;
}

String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
