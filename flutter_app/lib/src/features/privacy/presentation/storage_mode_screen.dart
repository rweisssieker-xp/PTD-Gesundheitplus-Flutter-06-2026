import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../data/local_privacy_repository.dart';

class StorageModeScreen extends ConsumerWidget {
  const StorageModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Speicher-Modus')),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          return FutureBuilder<LocalPrivacySnapshot>(
            future: LocalPrivacyRepository(db).snapshot(),
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
}
