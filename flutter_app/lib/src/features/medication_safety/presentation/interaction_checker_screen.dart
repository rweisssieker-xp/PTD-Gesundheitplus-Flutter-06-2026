import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../privacy/data/local_privacy_repository.dart';
import '../data/medication_safety_repository.dart';
import '../domain/medication_safety.dart';

class InteractionCheckerScreen extends ConsumerStatefulWidget {
  const InteractionCheckerScreen({super.key});

  @override
  ConsumerState<InteractionCheckerScreen> createState() =>
      _InteractionCheckerScreenState();
}

class _InteractionCheckerScreenState
    extends ConsumerState<InteractionCheckerScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Wechselwirkungen-Checker')),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final safety = MedicationSafetyRepository(db);
          final privacy = LocalPrivacyRepository(db);
          return FutureBuilder<List<Object>>(
            key: ValueKey(_reload),
            future: Future.wait([privacy.snapshot(), safety.listChecks()]),
            builder: (context, snapshot) {
              final privacySnapshot = snapshot.data == null
                  ? null
                  : snapshot.data![0] as LocalPrivacySnapshot;
              final checks = snapshot.data == null
                  ? <MedicationInteractionCheck>[]
                  : snapshot.data![1] as List<MedicationInteractionCheck>;
              final consentAllowed = privacySnapshot?.aiContextAllowed ?? false;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: consentAllowed ? null : GpColors.redSurface,
                    child: ListTile(
                      leading: Icon(
                        consentAllowed
                            ? Icons.verified_user_outlined
                            : Icons.lock_outline,
                        color: consentAllowed
                            ? GpColors.green.first
                            : GpColors.emergencyRed,
                      ),
                      title: Text(
                        consentAllowed
                            ? 'Kontextfreigabe aktiv'
                            : 'Kontextfreigabe fehlt',
                      ),
                      subtitle: const Text(
                        'Der Check nutzt nur lokal gespeicherte Medikamente.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await safety.runLocalCheck(
                        consentAllowed: consentAllowed,
                      );
                      if (mounted) setState(() => _reload++);
                    },
                    icon: const Icon(GpIcons.interactions),
                    label: const Text('Lokalen Check ausfuehren'),
                  ),
                  const SizedBox(height: 16),
                  if (checks.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('Noch keine Checks')),
                      ),
                    )
                  else
                    ...checks.map(
                      (check) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            GpIcons.interactions,
                            color: check.riskLevel == 'hoch'
                                ? GpColors.emergencyRed
                                : GpColors.textSecondary,
                          ),
                          title: Text('Risiko: ${check.riskLevel}'),
                          subtitle: Text(check.summary),
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
