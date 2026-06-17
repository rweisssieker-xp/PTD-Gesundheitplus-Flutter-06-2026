import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/native_notification_service.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
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
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = CareRepository(db);
          return FutureBuilder<List<DementiaLog>>(
            key: ValueKey(_reload),
            future: repo.listDementiaLogs(),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _quickLog(repo, 'Trinken', 'Wasser'),
                        icon: const Icon(Icons.water_drop_outlined),
                        label: const Text('Trinken'),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            _quickLog(repo, 'Mahlzeit', 'Gegessen'),
                        icon: const Icon(Icons.restaurant_outlined),
                        label: const Text('Mahlzeit'),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            _quickLog(repo, 'Erinnerung', 'Erledigt'),
                        icon: const Icon(Icons.alarm_on_outlined),
                        label: const Text('Erinnerung'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: GpColors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '${logs.length} lokale Pflege-Logs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (logs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('Noch keine Logs')),
                      ),
                    )
                  else
                    ...logs.map(
                      (log) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(_icon(log.type)),
                          title: Text('${log.type}: ${log.value}'),
                          subtitle: Text(
                            '${_date(log.loggedAt)}${log.note == null ? '' : ' • ${log.note}'}',
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

  Future<void> _quickLog(CareRepository repo, String type, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    await repo.addDementiaLog(type: type, value: value);
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
      'Trinken' => now.add(const Duration(hours: 2)),
      'Mahlzeit' => now.add(const Duration(hours: 5)),
      _ => now.add(const Duration(hours: 24)),
    };
    final title = switch (type) {
      'Trinken' => 'Trinken nicht vergessen',
      'Mahlzeit' => 'Mahlzeit pruefen',
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

  IconData _icon(String type) {
    return switch (type) {
      'Trinken' => Icons.water_drop_outlined,
      'Mahlzeit' => Icons.restaurant_outlined,
      _ => Icons.alarm_on_outlined,
    };
  }
}

String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';
