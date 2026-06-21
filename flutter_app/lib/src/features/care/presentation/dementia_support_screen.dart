import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/native_notification_service.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_database_error.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/care_repository.dart';
import '../domain/care.dart';

class DementiaSupportScreen extends ConsumerStatefulWidget {
  const DementiaSupportScreen({super.key});

  @override
  ConsumerState<DementiaSupportScreen> createState() =>
      _DementiaSupportScreenState();
}

class _DementiaSupportScreenState extends ConsumerState<DementiaSupportScreen> {
  int _reload = 0;
  final _notifications = NativeNotificationService();

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => GpDatabaseError(
          error: error,
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
        data: (db) {
          final repo = CareRepository(db);
          return FutureBuilder<List<DementiaLog>>(
            key: ValueKey(_reload),
            future: repo.listDementiaLogs(),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              final todayLogs = logs.where(_isToday).toList();
              final hydration = _hydrationTotal(todayLogs);
              final meals = todayLogs
                  .where((log) => log.type == _mealType)
                  .length
                  .clamp(0, _mealGoal);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                children: [
                  _PageHeader(onSettings: () => _openSettings(context)),
                  const SizedBox(height: 12),
                  const _SetupInfoCard(),
                  const SizedBox(height: 16),
                  _TodayStatusGrid(hydrationMl: hydration, meals: meals),
                  const SizedBox(height: 16),
                  _QuickActions(
                    onQuickHydration: () =>
                        _quickLog(repo, _hydrationType, '250 ml Wasser'),
                    onDetailedHydration: () => _openHydrationEditor(repo),
                    onMeal: () => _openMealEditor(repo),
                    onReminder: () =>
                        _quickLog(repo, _reminderType, 'Alltag erledigt'),
                  ),
                  const SizedBox(height: 16),
                  _LocalLogSummary(total: logs.length, today: todayLogs.length),
                  const SizedBox(height: 16),
                  _TodayLogsCard(logs: todayLogs),
                  const SizedBox(height: 16),
                  _AllLogsCard(logs: logs),
                  const SizedBox(height: 12),
                  const _CaregiverInfoCard(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openHydrationEditor(CareRepository repo) async {
    final saved = await showModalBottomSheet<_DementiaDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _HydrationEditor(),
    );
    if (saved != null) {
      await _quickLog(repo, saved.type, saved.value, note: saved.note);
    }
  }

  Future<void> _openMealEditor(CareRepository repo) async {
    final saved = await showModalBottomSheet<_DementiaDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _MealEditor(),
    );
    if (saved != null) {
      await _quickLog(repo, saved.type, saved.value, note: saved.note);
    }
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _SettingsSheet(),
    );
  }

  Future<void> _quickLog(
    CareRepository repo,
    String type,
    String value, {
    String? note,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    await repo.addDementiaLog(type: type, value: value, note: note);
    try {
      await _scheduleNextSupportReminder(type);
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Log gespeichert, naechste Erinnerung konnte nicht geplant werden.',
            ),
          ),
        );
      }
    }
    if (mounted) setState(() => _reload++);
  }

  Future<void> _scheduleNextSupportReminder(String type) async {
    final now = DateTime.now();
    final scheduledAt = switch (type) {
      _hydrationType => now.add(const Duration(hours: 2)),
      _mealType => now.add(const Duration(hours: 5)),
      _ => now.add(const Duration(hours: 24)),
    };
    final title = switch (type) {
      _hydrationType => 'Trinken nicht vergessen',
      _mealType => 'Mahlzeit pruefen',
      _ => 'Alltagserinnerung pruefen',
    };
    final reminder = NotificationScheduler().dementiaSupportReminder(
      type: type,
      title: title,
      scheduledAt: scheduledAt,
      now: now,
    );
    if (reminder == null) return;
    await _notifications.scheduleReminder(
      reminder,
      body: 'Lokale Demenz-Unterstuetzung',
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.favorite_border, color: Color(0xFFDB2777), size: 30),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Demenz-Unterstützung',
                style: TextStyle(
                  color: GpColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Erinnerungen & Protokolle lokal auf diesem Gerät',
                style: TextStyle(color: GpColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          tooltip: 'Einstellungen',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _SetupInfoCard extends StatelessWidget {
  const _SetupInfoCard();

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
            Icon(Icons.info_outline, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Diese Funktion hilft bei beginnender Demenz durch regelmaessige Erinnerungen an Trinken, Essen und Routinen. Alle Protokolle bleiben lokal.',
                style: TextStyle(color: Color(0xFF1E40AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayStatusGrid extends StatelessWidget {
  const _TodayStatusGrid({required this.hydrationMl, required this.meals});

  final int hydrationMl;
  final int meals;

  @override
  Widget build(BuildContext context) {
    final hydrationProgress = (hydrationMl / _hydrationGoal).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: _HydrationStatusCard(
            hydrationMl: hydrationMl,
            progress: hydrationProgress,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _MealStatusCard(meals: meals)),
      ],
    );
  }
}

class _HydrationStatusCard extends StatelessWidget {
  const _HydrationStatusCard({
    required this.hydrationMl,
    required this.progress,
  });

  final int hydrationMl;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Icon(
              Icons.water_drop_outlined,
              color: Color(0xFF2563EB),
              size: 38,
            ),
            const SizedBox(height: 8),
            Text(
              '$hydrationMl',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const Text('ml getrunken'),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ziel: 2000 ml',
              style: TextStyle(color: GpColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealStatusCard extends StatelessWidget {
  const _MealStatusCard({required this.meals});

  final int meals;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const Icon(
              Icons.restaurant_outlined,
              color: Color(0xFFF97316),
              size: 38,
            ),
            const SizedBox(height: 8),
            Text(
              '$meals',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const Text('Mahlzeiten'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _mealGoal; i++) ...[
                  Icon(
                    i < meals ? Icons.check_circle : Icons.schedule,
                    color: i < meals
                        ? const Color(0xFFF97316)
                        : GpColors.textSecondary,
                  ),
                  if (i != _mealGoal - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onQuickHydration,
    required this.onDetailedHydration,
    required this.onMeal,
    required this.onReminder,
  });

  final VoidCallback onQuickHydration;
  final VoidCallback onDetailedHydration;
  final VoidCallback onMeal;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GradientActionButton(
                label: 'Getrunken (250ml)',
                icon: Icons.water_drop_outlined,
                colors: const [Color(0xFF38BDF8), Color(0xFF2563EB)],
                onTap: onQuickHydration,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OutlineActionButton(
                label: 'Trinken detailliert',
                icon: Icons.add,
                onTap: onDetailedHydration,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GradientActionButton(
                label: 'Mahlzeit gegessen',
                icon: Icons.restaurant_outlined,
                colors: const [Color(0xFFFB923C), Color(0xFFF97316)],
                onTap: onMeal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OutlineActionButton(
                label: 'Routine erledigt',
                icon: Icons.alarm_on_outlined,
                onTap: onReminder,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 78,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(78),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _LocalLogSummary extends StatelessWidget {
  const _LocalLogSummary({required this.total, required this.today});

  final int total;
  final int today;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: GpColors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.fact_check_outlined,
              color: Colors.white,
              size: 42,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '$today heute • $total lokale Pflege-Logs',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayLogsCard extends StatelessWidget {
  const _TodayLogsCard({required this.logs});

  final List<DementiaLog> logs;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Heute protokolliert',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (logs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Noch keine Einträge heute'),
                ),
              )
            else
              ...logs.take(8).map((log) => _DementiaLogTile(log: log)),
          ],
        ),
      ),
    );
  }
}

class _AllLogsCard extends StatelessWidget {
  const _AllLogsCard({required this.logs});

  final List<DementiaLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: Text('Noch keine Logs')),
        ),
      );
    }
    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        title: const Text('Alle lokalen Pflege-Logs'),
        children: logs
            .take(20)
            .map((log) => _DementiaLogTile(log: log))
            .toList(),
      ),
    );
  }
}

class _DementiaLogTile extends StatelessWidget {
  const _DementiaLogTile({required this.log});

  final DementiaLog log;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_icon(log.type), color: _color(log.type)),
      title: Text('${log.type}: ${log.value}'),
      subtitle: Text(
        '${_dateTime(log.loggedAt)}${log.note == null ? '' : ' • ${log.note}'}',
      ),
      trailing: _Badge(label: _time(log.loggedAt)),
    );
  }
}

class _CaregiverInfoCard extends StatelessWidget {
  const _CaregiverInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF0FDF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBBF7D0), width: 2),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.groups_outlined, color: Color(0xFF16A34A)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Für Betreuer & Familie: Regelmaessige Routinen, Trink- und Essprotokolle koennen haeusliche Pflege und ambulante Dienste unterstuetzen.',
                style: TextStyle(color: Color(0xFF166534)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Einstellungen',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 12),
          _SettingRow(
            icon: Icons.favorite_border,
            title: 'Demenz-Unterstützung',
            text: 'Lokale Erinnerungen fuer Trinken, Essen und Alltag.',
          ),
          _SettingRow(
            icon: Icons.water_drop_outlined,
            title: 'Trinkerinnerungen',
            text: 'Nach Trink-Logs wird lokal die naechste Erinnerung geplant.',
          ),
          _SettingRow(
            icon: Icons.restaurant_outlined,
            title: 'Essenserinnerungen',
            text: 'Nach Mahlzeiten wird eine lokale Folgeerinnerung geplant.',
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFDB2777)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  text,
                  style: const TextStyle(color: GpColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrationEditor extends StatefulWidget {
  const _HydrationEditor();

  @override
  State<_HydrationEditor> createState() => _HydrationEditorState();
}

class _HydrationEditorState extends State<_HydrationEditor> {
  var _beverage = 'Wasser';
  var _amount = 250;

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      title: 'Trinken protokollieren',
      children: [
        DropdownButtonFormField<String>(
          initialValue: _beverage,
          decoration: const InputDecoration(labelText: 'Getränk'),
          items: const [
            DropdownMenuItem(value: 'Wasser', child: Text('Wasser')),
            DropdownMenuItem(value: 'Tee', child: Text('Tee')),
            DropdownMenuItem(value: 'Kaffee', child: Text('Kaffee')),
            DropdownMenuItem(value: 'Saft', child: Text('Saft')),
            DropdownMenuItem(value: 'Milch', child: Text('Milch')),
            DropdownMenuItem(value: 'Suppe', child: Text('Suppe')),
          ],
          onChanged: (value) => setState(() => _beverage = value ?? 'Wasser'),
        ),
        DropdownButtonFormField<int>(
          initialValue: _amount,
          decoration: const InputDecoration(labelText: 'Menge (ml)'),
          items: const [
            DropdownMenuItem(value: 100, child: Text('100 ml')),
            DropdownMenuItem(value: 200, child: Text('200 ml')),
            DropdownMenuItem(value: 250, child: Text('250 ml')),
            DropdownMenuItem(value: 300, child: Text('300 ml')),
            DropdownMenuItem(value: 500, child: Text('500 ml')),
          ],
          onChanged: (value) => setState(() => _amount = value ?? 250),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _DementiaDraft(
              type: _hydrationType,
              value: '$_amount ml $_beverage',
              note: 'Getraenk: $_beverage',
            ),
          ),
          child: const Text('Protokollieren'),
        ),
      ],
    );
  }
}

class _MealEditor extends StatefulWidget {
  const _MealEditor();

  @override
  State<_MealEditor> createState() => _MealEditorState();
}

class _MealEditorState extends State<_MealEditor> {
  var _meal = 'Fruehstueck';
  var _portion = 'Normal';

  @override
  Widget build(BuildContext context) {
    return _EditorShell(
      title: 'Mahlzeit protokollieren',
      children: [
        DropdownButtonFormField<String>(
          initialValue: _meal,
          decoration: const InputDecoration(labelText: 'Mahlzeit'),
          items: const [
            DropdownMenuItem(value: 'Fruehstueck', child: Text('Frühstück')),
            DropdownMenuItem(value: 'Mittagessen', child: Text('Mittagessen')),
            DropdownMenuItem(value: 'Abendessen', child: Text('Abendessen')),
            DropdownMenuItem(value: 'Snack', child: Text('Snack')),
          ],
          onChanged: (value) => setState(() => _meal = value ?? 'Fruehstueck'),
        ),
        DropdownButtonFormField<String>(
          initialValue: _portion,
          decoration: const InputDecoration(labelText: 'Portionsgröße'),
          items: const [
            DropdownMenuItem(value: 'Keine', child: Text('Keine')),
            DropdownMenuItem(value: 'Klein', child: Text('Klein')),
            DropdownMenuItem(value: 'Normal', child: Text('Normal')),
            DropdownMenuItem(value: 'Gross', child: Text('Groß')),
          ],
          onChanged: (value) => setState(() => _portion = value ?? 'Normal'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _DementiaDraft(
              type: _mealType,
              value: _meal,
              note: 'Portion: $_portion',
            ),
          ),
          child: const Text('Protokollieren'),
        ),
      ],
    );
  }
}

class _EditorShell extends StatelessWidget {
  const _EditorShell({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
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
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _DementiaDraft {
  const _DementiaDraft({required this.type, required this.value, this.note});

  final String type;
  final String value;
  final String? note;
}

const _hydrationType = 'Trinken';
const _mealType = 'Mahlzeit';
const _reminderType = 'Erinnerung';
const _hydrationGoal = 2000;
const _mealGoal = 3;

bool _isToday(DementiaLog log) {
  final now = DateTime.now();
  return log.loggedAt.year == now.year &&
      log.loggedAt.month == now.month &&
      log.loggedAt.day == now.day;
}

int _hydrationTotal(List<DementiaLog> logs) {
  var total = 0;
  for (final log in logs.where((item) => item.type == _hydrationType)) {
    final match = RegExp(r'(\d{2,4})\s*ml').firstMatch(log.value);
    total += match == null ? 250 : int.parse(match.group(1)!);
  }
  return total;
}

IconData _icon(String type) {
  return switch (type) {
    _hydrationType => Icons.water_drop_outlined,
    _mealType => Icons.restaurant_outlined,
    _ => Icons.alarm_on_outlined,
  };
}

Color _color(String type) {
  return switch (type) {
    _hydrationType => const Color(0xFF2563EB),
    _mealType => const Color(0xFFF97316),
    _ => const Color(0xFF16A34A),
  };
}

String _dateTime(DateTime value) =>
    '${value.day}.${value.month}.${value.year} ${_time(value)}';

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
