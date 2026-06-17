import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/medication_repository.dart';
import '../domain/medication_intake_text_parser.dart';
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
  final _voiceConfirmationText = TextEditingController();
  MedicationLog? _voiceConfirmationLog;
  String? _voiceConfirmationError;

  @override
  void dispose() {
    _voiceConfirmationText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(_selectedDate);
    return GpScreen(
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
                        onVoiceConfirm: _isToday(_selectedDate)
                            ? () => _openVoiceConfirmation(log)
                            : null,
                      ),
                    ),
                  if (_voiceConfirmationLog != null) ...[
                    const SizedBox(height: 8),
                    _VoiceConfirmationCard(
                      log: _voiceConfirmationLog!,
                      controller: _voiceConfirmationText,
                      error: _voiceConfirmationError,
                      onCancel: _closeVoiceConfirmation,
                      onConfirm: () => _submitVoiceConfirmation(repo),
                    ),
                  ],
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

  void _openVoiceConfirmation(MedicationLog log) {
    setState(() {
      _voiceConfirmationLog = log;
      _voiceConfirmationText.clear();
      _voiceConfirmationError = null;
    });
  }

  void _closeVoiceConfirmation() {
    setState(() {
      _voiceConfirmationLog = null;
      _voiceConfirmationText.clear();
      _voiceConfirmationError = null;
    });
  }

  Future<void> _submitVoiceConfirmation(MedicationRepository repo) async {
    final log = _voiceConfirmationLog;
    if (log == null) return;
    final result = const MedicationIntakeTextParser().parse(
      _voiceConfirmationText.text,
    );
    if (result.decision == MedicationIntakeDecision.unknown) {
      setState(() {
        _voiceConfirmationError =
            'Bitte "eingenommen" oder "nicht eingenommen" eingeben.';
      });
      return;
    }

    final status = result.decision == MedicationIntakeDecision.taken
        ? MedicationLogStatus.taken
        : MedicationLogStatus.skipped;
    await repo.updateLogStatus(
      log.id,
      status,
      takenAt: status == MedicationLogStatus.taken ? DateTime.now() : null,
      notes: result.note.isEmpty ? null : result.note,
      confirmedByVoice: status == MedicationLogStatus.taken,
    );
    setState(() {
      _voiceConfirmationLog = null;
      _voiceConfirmationText.clear();
      _voiceConfirmationError = null;
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
  const _MedicationLogCard({
    required this.log,
    required this.onStatus,
    required this.onVoiceConfirm,
  });

  final MedicationLog log;
  final ValueChanged<MedicationLogStatus> onStatus;
  final VoidCallback? onVoiceConfirm;

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
                  if (log.confirmedByVoice)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Chip(
                        avatar: Icon(Icons.mic_outlined, size: 16),
                        label: Text('Per Sprache'),
                      ),
                    ),
                  if ((log.notes ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        log.notes!,
                        style: const TextStyle(
                          color: GpColors.textSecondary,
                          fontSize: 12,
                        ),
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
                tooltip: 'Sprache',
                onPressed: onVoiceConfirm,
                icon: const Icon(Icons.mic_outlined, color: Colors.purple),
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

class _VoiceConfirmationCard extends StatelessWidget {
  const _VoiceConfirmationCard({
    required this.log,
    required this.controller,
    required this.error,
    required this.onCancel,
    required this.onConfirm,
  });

  final MedicationLog log;
  final TextEditingController controller;
  final String? error;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFAF5FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFD8B4FE), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.mic_outlined, color: Color(0xFF7E22CE)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokale Einnahme-Bestätigung',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${log.medicationName} um ${log.scheduledTime} Uhr',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Antwort eingeben',
                hintText: 'Ja, eingenommen / Nein, nicht eingenommen',
                border: OutlineInputBorder(),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
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
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Auswerten'),
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

class _StatusConfig {
  const _StatusConfig(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
