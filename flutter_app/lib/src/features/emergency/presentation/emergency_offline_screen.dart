import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/emergency_repository.dart';
import '../domain/emergency_payload_builder.dart';
import '../domain/emergency_profile.dart';
import 'emergency_contact_actions.dart';

class EmergencyOfflineScreen extends ConsumerWidget {
  const EmergencyOfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  const _Header(),
                  const SizedBox(height: 16),
                  _ReadinessBanner(profile: profile),
                  const SizedBox(height: 16),
                  _PersonalDataCard(profile: profile),
                  const SizedBox(height: 16),
                  _QrCard(profile: profile, payload: payload),
                  if (profile.criticalWarnings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _WarningCard(warnings: profile.criticalWarnings),
                  ],
                  if (profile.immediateActions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ImmediateActionsCard(actions: profile.immediateActions),
                  ],
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Diagnosen',
                    icon: GpIcons.anamnesis,
                    values: profile.diagnoses,
                    empty: 'Keine aktiven Diagnosen gespeichert',
                    tint: const Color(0xFFEFF6FF),
                    border: const Color(0xFFBFDBFE),
                    iconColor: const Color(0xFF2563EB),
                  ),
                  _Section(
                    title: 'Allergien',
                    icon: GpIcons.allergies,
                    values: profile.allergies,
                    empty: 'Keine Allergien gespeichert',
                    tint: const Color(0xFFFEFCE8),
                    border: const Color(0xFFFDE68A),
                    iconColor: const Color(0xFFCA8A04),
                  ),
                  _Section(
                    title: 'Aktuelle Medikamente',
                    icon: GpIcons.medication,
                    values: profile.medications,
                    empty: 'Keine aktive Medikation gespeichert',
                    tint: const Color(0xFFF0FDF4),
                    border: const Color(0xFFBBF7D0),
                    iconColor: const Color(0xFF16A34A),
                  ),
                  EmergencyContactsSection(contacts: profile.contacts),
                  const SizedBox(height: 6),
                  _LockscreenCard(payload: payload),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(GpIcons.shield, color: GpColors.emergencyRed, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Offline-Notfalldaten',
                      style: TextStyle(
                        color: GpColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Immer verfügbar, auch ohne Internet.',
                style: TextStyle(color: GpColors.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Lokal',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadinessBanner extends StatelessWidget {
  const _ReadinessBanner({required this.profile});

  final EmergencyProfile profile;

  @override
  Widget build(BuildContext context) {
    final missing = [
      if (profile.fullName == 'Patient') 'Name',
      if (profile.contacts.isEmpty) 'Notfallkontakt',
      if (profile.allergies.isEmpty && profile.medications.isEmpty)
        'Medikation/Allergien',
    ];
    final ready = missing.isEmpty;
    return Card(
      color: ready ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: ready ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          ready ? Icons.check_circle : Icons.warning_amber_outlined,
          color: ready ? const Color(0xFF16A34A) : const Color(0xFFCA8A04),
        ),
        title: Text(
          ready
              ? 'Offline-Notfallprofil bereit'
              : 'Notfallprofil unvollständig',
        ),
        subtitle: Text(
          ready
              ? 'QR-Code, Kontakte und kritische Gesundheitsdaten sind lokal verfügbar.'
              : 'Fehlt noch: ${missing.join(', ')}',
        ),
      ),
    );
  }
}

class _PersonalDataCard extends StatelessWidget {
  const _PersonalDataCard({required this.profile});

  final EmergencyProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBFDBFE), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.person_outline,
              iconColor: Color(0xFF2563EB),
              title: 'Persönliche Daten',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ValueTile(label: 'Name', value: profile.fullName),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ValueTile(
                    label: 'Geburtsdatum',
                    value: _formatDate(profile.dateOfBirth),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ValueTile(label: 'Hinweise', value: profile.notes),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return 'Nicht hinterlegt';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.profile, required this.payload});

  final EmergencyProfile profile;
  final String payload;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GpColors.redSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
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
            const SizedBox(height: 10),
            Text(
              profile.fullName,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'QR-Code für Ersthelfer',
              textAlign: TextAlign.center,
              style: TextStyle(color: GpColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: QrImageView(data: payload, size: 220),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: payload));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notfall-QR-Daten kopiert')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('QR-Daten kopieren'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFEF2F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFFCA5A5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.warning_amber_outlined,
              iconColor: GpColors.emergencyRed,
              title: 'Kritische Warnungen',
            ),
            const SizedBox(height: 12),
            for (final warning in warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• $warning',
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
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

class _ImmediateActionsCard extends StatelessWidget {
  const _ImmediateActionsCard({required this.actions});

  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.check_circle_outline,
              iconColor: Color(0xFF16A34A),
              title: 'Sofortmaßnahmen',
            ),
            const SizedBox(height: 12),
            for (final action in actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('✓ $action'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.values,
    required this.empty,
    required this.tint,
    required this.border,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final List<String> values;
  final String empty;
  final Color tint;
  final Color border;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: tint,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: border, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(icon: icon, iconColor: iconColor, title: title),
            const SizedBox(height: 10),
            if (values.isEmpty)
              Text(empty, style: const TextStyle(color: GpColors.textSecondary))
            else
              ...values.map(
                (value) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LockscreenCard extends StatelessWidget {
  const _LockscreenCard({required this.payload});

  final String payload;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF9FAFB),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.smartphone_outlined,
              iconColor: Color(0xFF4B5563),
              title: 'Sperrbildschirm vorbereiten',
            ),
            const SizedBox(height: 8),
            const Text(
              'Für maximale Offline-Verfügbarkeit können Sie diesen QR-Code als Screenshot sichern und als Sperrbildschirm-Hinweis nutzen.',
              style: TextStyle(color: GpColors.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: payload));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Offline-Notfalldaten kopiert'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Daten für Backup kopieren'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: GpColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: GpColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}
