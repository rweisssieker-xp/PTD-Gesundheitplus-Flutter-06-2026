import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/local_privacy_repository.dart';

class StorageModeScreen extends ConsumerStatefulWidget {
  const StorageModeScreen({super.key});

  @override
  ConsumerState<StorageModeScreen> createState() => _StorageModeScreenState();
}

class _StorageModeScreenState extends ConsumerState<StorageModeScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = LocalPrivacyRepository(db);
          return FutureBuilder<LocalPrivacySnapshot>(
            key: ValueKey(_reload),
            future: repo.snapshot(),
            builder: (context, snapshot) {
              final counts =
                  snapshot.data?.tableCounts ?? const <String, int>{};
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.storage_outlined,
                        color: GpColors.emergencyRed,
                      ),
                      title: Text('Alles lokal auf dem Device'),
                      subtitle: Text(
                        'Die App nutzt eine lokale SQLite-Datei im App-Speicher.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: const Color(0xFFFEF2F2),
                    child: ListTile(
                      leading: const Icon(
                        Icons.delete_forever_outlined,
                        color: GpColors.emergencyRed,
                      ),
                      title: const Text('Alle lokalen Daten löschen'),
                      subtitle: const Text(
                        'Entfernt alle lokal gespeicherten App-Daten von diesem Gerät.',
                      ),
                      onTap: snapshot.hasData
                          ? () => _confirmClear(repo)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...counts.entries.map(
                    (entry) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(entry.key),
                        trailing: Text('${entry.value}'),
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

  Future<void> _confirmClear(LocalPrivacyRepository repo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle lokalen Daten löschen?'),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden und löscht auch lokale Einstellungen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GpColors.emergencyRed,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await repo.clearAllLocalData();
    if (!mounted) return;
    setState(() => _reload++);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lokale Daten wurden gelöscht.')),
    );
  }
}
