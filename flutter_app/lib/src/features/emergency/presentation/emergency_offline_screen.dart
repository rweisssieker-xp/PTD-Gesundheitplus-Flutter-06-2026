import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../data/emergency_repository.dart';
import '../domain/emergency_payload_builder.dart';
import '../domain/emergency_profile.dart';

class EmergencyOfflineScreen extends ConsumerWidget {
  const EmergencyOfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Offline-Notfall')),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = EmergencyRepository(db);
          return FutureBuilder<EmergencyProfile>(
            future: repo.buildLocalProfile(),
            builder: (context, snapshot) {
              final profile =
                  snapshot.data ??
                  const EmergencyProfile(
                    fullName: 'Patient',
                    notes: 'Lokales Notfallprofil',
                    medications: [],
                    allergies: [],
                    diagnoses: [],
                    contacts: [],
                  );
              final payload = EmergencyPayloadBuilder().build(profile);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: GpColors.redSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            GpIcons.emergency,
                            color: GpColors.emergencyRed,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.fullName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          QrImageView(data: payload, size: 220),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Medikation',
                    values: profile.medications,
                    empty: 'Keine aktive Medikation gespeichert',
                  ),
                  _Section(
                    title: 'Allergien',
                    values: profile.allergies,
                    empty: 'Keine Allergien gespeichert',
                  ),
                  _Section(
                    title: 'Notfallkontakte',
                    values: profile.contacts
                        .map((contact) => '${contact.name}: ${contact.phone}')
                        .toList(),
                    empty: 'Keine Kontakte mit Telefonnummer',
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.values,
    required this.empty,
  });

  final String title;
  final List<String> values;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (values.isEmpty)
              Text(empty, style: const TextStyle(color: GpColors.textSecondary))
            else
              ...values.map(
                (value) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
