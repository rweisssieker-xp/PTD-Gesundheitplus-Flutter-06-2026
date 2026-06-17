import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Demenz-Unterstuetzung')),
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
    await repo.addDementiaLog(type: type, value: value);
    if (mounted) setState(() => _reload++);
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
