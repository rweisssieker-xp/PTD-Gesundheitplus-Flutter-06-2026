import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../data/local_privacy_repository.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Datenschutz')),
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
              final data = snapshot.data;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: GpColors.grayDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 42,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Lokaler Speicher aktiv',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '${data?.totalRows ?? 0} lokale Datensaetze',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: data?.aiContextAllowed ?? false,
                    onChanged: data == null
                        ? null
                        : (value) async {
                            await repo.setAiContextAllowed(value);
                            if (mounted) setState(() => _reload++);
                          },
                    title: const Text('KI-Kontext freigeben'),
                    subtitle: const Text(
                      'Wenn aus, bleiben Gesundheitsdaten vom KI-Kontext getrennt.',
                    ),
                  ),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.phone_android_outlined),
                      title: Text('Device-only Modus'),
                      subtitle: Text(
                        'Medikation, Termine, Vitalwerte und Notfalldaten werden lokal gespeichert.',
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
