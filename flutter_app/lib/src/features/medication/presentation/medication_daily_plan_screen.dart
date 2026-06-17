import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../data/medication_repository.dart';
import '../domain/medication.dart';

class MedicationDailyPlanScreen extends ConsumerStatefulWidget {
  const MedicationDailyPlanScreen({super.key});

  @override
  ConsumerState<MedicationDailyPlanScreen> createState() =>
      _MedicationDailyPlanScreenState();
}

class _MedicationDailyPlanScreenState
    extends ConsumerState<MedicationDailyPlanScreen> {
  DateTime _selectedDate = DateTime.now();
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(_selectedDate);
    return Scaffold(
      appBar: AppBar(title: const Text('Medikamenten-Tagesplan')),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = MedicationRepository(db);
          return FutureBuilder<List<MedicationLog>>(
            key: ValueKey('$_reload-${_selectedDate.toIso8601String()}'),
            future: repo.ensureDailyLogs(_selectedDate),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              final taken = logs
                  .where((log) => log.status == MedicationLogStatus.taken)
                  .length;
              final rate = logs.isEmpty
                  ? 0
                  : ((taken / logs.length) * 100).round();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => _changeDate(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  dateLabel,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (_isToday(_selectedDate))
                                  const Chip(label: Text('Heute')),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _isToday(_selectedDate)
                                ? null
                                : () => _changeDate(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Eingenommen',
                          value: '$taken/${logs.length}',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Treue-Rate',
                          value: '$rate%',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (logs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: Text('Keine Erinnerungen fuer diesen Tag'),
                        ),
                      ),
                    )
                  else
                    ...logs.map(
                      (log) => _MedicationLogCard(
                        log: log,
                        onStatus: (status) => _setStatus(repo, log, status),
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

  Future<void> _setStatus(
    MedicationRepository repo,
    MedicationLog log,
    MedicationLogStatus status,
  ) async {
    await repo.updateLogStatus(
      log.id,
      status,
      takenAt: status == MedicationLogStatus.taken ? DateTime.now() : null,
    );
    setState(() {
      _reload++;
    });
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + days,
      );
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationLogCard extends StatelessWidget {
  const _MedicationLogCard({required this.log, required this.onStatus});

  final MedicationLog log;
  final ValueChanged<MedicationLogStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(log.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: config.color.withValues(alpha: 0.12),
              child: Icon(config.icon, color: config.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.medicationName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${log.scheduledTime} Uhr${log.dosageTaken == null ? '' : ' • ${log.dosageTaken}'}',
                  ),
                  Text(
                    config.label,
                    style: TextStyle(
                      color: config.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (log.status == MedicationLogStatus.pending) ...[
              IconButton(
                tooltip: 'Eingenommen',
                onPressed: () => onStatus(MedicationLogStatus.taken),
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
              IconButton(
                tooltip: 'Ueberspringen',
                onPressed: () => onStatus(MedicationLogStatus.skipped),
                icon: const Icon(Icons.cancel_outlined, color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(MedicationLogStatus status) {
    return switch (status) {
      MedicationLogStatus.taken => const _StatusConfig(
        'Eingenommen',
        Icons.check_circle,
        Colors.green,
      ),
      MedicationLogStatus.skipped => const _StatusConfig(
        'Uebersprungen',
        Icons.remove_circle_outline,
        Colors.orange,
      ),
      MedicationLogStatus.missed => const _StatusConfig(
        'Verpasst',
        Icons.error_outline,
        GpColors.emergencyRed,
      ),
      MedicationLogStatus.pending => const _StatusConfig(
        'Ausstehend',
        Icons.radio_button_unchecked,
        Colors.grey,
      ),
    };
  }
}

class _StatusConfig {
  const _StatusConfig(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
