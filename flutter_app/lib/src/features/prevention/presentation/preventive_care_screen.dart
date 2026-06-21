import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/native_notification_service.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_database_error.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/prevention_repository.dart';
import '../domain/prevention.dart';

class PreventiveCareScreen extends ConsumerStatefulWidget {
  const PreventiveCareScreen({super.key});

  @override
  ConsumerState<PreventiveCareScreen> createState() =>
      _PreventiveCareScreenState();
}

class _PreventiveCareScreenState extends ConsumerState<PreventiveCareScreen> {
  int _reload = 0;
  final _notifications = NativeNotificationService();

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openEditor(PreventionRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Termin'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => GpDatabaseError(
          error: error,
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
        data: (db) {
          final repo = PreventionRepository(db);
          return FutureBuilder<PreventiveCareSnapshot>(
            key: ValueKey(_reload),
            future: repo.snapshot(),
            builder: (context, snapshot) {
              final items = snapshot.data?.items ?? [];
              final recommendations = snapshot.data?.recommendations ?? [];
              final due = items.where((item) => item.isDue).length;
              final upcoming = items.where(_isUpcoming).length;
              final active = items.where((item) => !item.isDone).length;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                children: [
                  _PreventiveCareHeader(due: due),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ReminderStatsRow(
                      active: active,
                      upcoming: upcoming,
                      total: items.length,
                    ),
                    const SizedBox(height: 16),
                    const _LocalReminderInfoCard(),
                  ] else
                    const SizedBox(height: 16),
                  if (items.isNotEmpty) const SizedBox(height: 16),
                  if (recommendations.isNotEmpty) ...[
                    _RecommendationPanel(
                      recommendations: recommendations.take(5).toList(),
                      onPlan: (recommendation) async {
                        await _planRecommendation(repo, recommendation);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('Noch keine Vorsorge')),
                      ),
                    )
                  else
                    ...items.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            item.isDone
                                ? Icons.check_circle_outline
                                : GpIcons.prevention,
                            color: item.isDue
                                ? GpColors.emergencyRed
                                : GpColors.green.first,
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.category} • ${_date(item.dueAt)}'
                            '${item.doctorName == null ? '' : ' • ${item.doctorName}'}',
                          ),
                          trailing: item.isDone
                              ? const Text('Erledigt')
                              : IconButton(
                                  tooltip: 'Als erledigt markieren',
                                  icon: const Icon(Icons.done),
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    await repo.markPreventiveCareDone(item.id);
                                    try {
                                      await _cancelPreventiveCareReminder(item);
                                    } catch (_) {
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Vorsorge erledigt, Erinnerung konnte nicht entfernt werden.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
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

  bool _isUpcoming(PreventiveCareItem item) {
    if (item.isDone) return false;
    final now = DateTime.now();
    final inThirtyDays = now.add(const Duration(days: 30));
    return !item.dueAt.isBefore(now) && !item.dueAt.isAfter(inThirtyDays);
  }

  Future<void> _openEditor(PreventionRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PreventiveCareEditor(
        repo: repo,
        schedulePreventiveCare: _schedulePreventiveCareReminder,
      ),
    );
    if (saved == true) setState(() => _reload++);
  }

  Future<void> _schedulePreventiveCareReminder(PreventiveCareItem item) async {
    if (item.isDone) return;
    final reminder = NotificationScheduler().preventiveCareReminder(
      itemId: item.id,
      title: item.title,
      dueAt: item.dueAt,
      now: DateTime.now(),
    );
    if (reminder == null) return;
    await _notifications.scheduleReminder(
      reminder,
      body: [item.category, item.doctorName, _date(item.dueAt)]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(' • '),
    );
  }

  Future<void> _cancelPreventiveCareReminder(PreventiveCareItem item) {
    return _notifications.cancelPreventiveCareReminder(item.id);
  }

  Future<void> _planRecommendation(
    PreventionRepository repo,
    PreventionRecommendation recommendation,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final item = await repo.addPreventiveCare(
      title: recommendation.title,
      category: recommendation.category,
      dueAt: recommendation.dueAt,
      intervalMonths: recommendation.intervalMonths,
      doctorName: recommendation.doctorName,
      notes: recommendation.reason,
    );
    try {
      await _schedulePreventiveCareReminder(item);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Empfehlung geplant, Erinnerung konnte nicht erstellt werden.',
          ),
        ),
      );
    }
    if (!mounted) return;
    setState(() => _reload++);
    messenger.showSnackBar(
      SnackBar(content: Text('${recommendation.title} geplant.')),
    );
  }
}

class _PreventiveCareHeader extends StatelessWidget {
  const _PreventiveCareHeader({required this.due});

  final int due;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(GpIcons.prevention, color: Color(0xFF4F46E5), size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vorsorge & Praevention',
                    style: TextStyle(
                      color: GpColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Personalisierte Gesundheitsempfehlungen',
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
            gradient: const LinearGradient(colors: GpColors.green),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(GpIcons.prevention, color: Colors.white, size: 46),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vorsorgeplan',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '$due faellig',
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
      ],
    );
  }
}

class _ReminderStatsRow extends StatelessWidget {
  const _ReminderStatsRow({
    required this.active,
    required this.upcoming,
    required this.total,
  });

  final int active;
  final int upcoming;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReminderStatTile(
            icon: Icons.notifications_active_outlined,
            value: '$active',
            label: 'Aktive Reminder',
            color: const Color(0xFF2563EB),
            background: const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ReminderStatTile(
            icon: Icons.calendar_month_outlined,
            value: '$upcoming',
            label: 'In 30 Tagen',
            color: const Color(0xFFF97316),
            background: const Color(0xFFFFF7ED),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ReminderStatTile(
            icon: Icons.check_circle_outline,
            value: '$total',
            label: 'Gesamt',
            color: const Color(0xFF16A34A),
            background: const Color(0xFFF0FDF4),
          ),
        ),
      ],
    );
  }
}

class _ReminderStatTile extends StatelessWidget {
  const _ReminderStatTile({
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
      height: 118,
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
            maxLines: 2,
            textAlign: TextAlign.center,
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

class _LocalReminderInfoCard extends StatelessWidget {
  const _LocalReminderInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBFDBFE)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Erinnerungen werden lokal auf diesem Geraet geplant. Es gibt keinen Cloud-Sync und keine Server-Speicherung.',
                style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationPanel extends StatelessWidget {
  const _RecommendationPanel({
    required this.recommendations,
    required this.onPlan,
  });

  final List<PreventionRecommendation> recommendations;
  final ValueChanged<PreventionRecommendation> onPlan;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF0FDF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBBF7D0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokale Vorsorge-Empfehlungen',
                    style: TextStyle(
                      color: GpColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Basierend auf Alter, lokalen Impfungen und geplanten Vorsorgen.',
              style: TextStyle(color: GpColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final recommendation in recommendations)
              _RecommendationTile(
                recommendation: recommendation,
                onPlan: () => onPlan(recommendation),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.recommendation,
    required this.onPlan,
  });

  final PreventionRecommendation recommendation;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final color = recommendation.isHighPriority
        ? GpColors.emergencyRed
        : GpColors.green.first;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                recommendation.category == 'Impfung'
                    ? GpIcons.vaccination
                    : GpIcons.prevention,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: const TextStyle(
                        color: GpColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${recommendation.category} • ${recommendation.urgency}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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

class _PreventiveCareEditor extends StatefulWidget {
  const _PreventiveCareEditor({
    required this.repo,
    required this.schedulePreventiveCare,
  });

  final PreventionRepository repo;
  final Future<void> Function(PreventiveCareItem item) schedulePreventiveCare;

  @override
  State<_PreventiveCareEditor> createState() => _PreventiveCareEditorState();
}

class _PreventiveCareEditorState extends State<_PreventiveCareEditor> {
  final _title = TextEditingController();
  final _category = TextEditingController(text: 'Check-up');
  final _doctor = TextEditingController();
  final _dueInDays = TextEditingController(text: '30');
  final _intervalMonths = TextEditingController();

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
              'Vorsorge planen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titel *'),
            ),
            TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Kategorie'),
            ),
            TextField(
              controller: _doctor,
              decoration: const InputDecoration(labelText: 'Arzt / Praxis'),
            ),
            TextField(
              controller: _dueInDays,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Faellig in Tagen'),
            ),
            TextField(
              controller: _intervalMonths,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Wiederholung in Monaten',
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
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final days = int.tryParse(_dueInDays.text) ?? 0;
    final item = await widget.repo.addPreventiveCare(
      title: title,
      category: _emptyToNull(_category.text) ?? 'Vorsorge',
      dueAt: DateTime.now().add(Duration(days: days)),
      intervalMonths: int.tryParse(_intervalMonths.text),
      doctorName: _emptyToNull(_doctor.text),
    );
    try {
      await widget.schedulePreventiveCare(item);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vorsorge gespeichert, Erinnerung konnte nicht geplant werden.',
            ),
          ),
        );
      }
    }
    if (mounted) Navigator.pop(context, true);
  }
}

String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
