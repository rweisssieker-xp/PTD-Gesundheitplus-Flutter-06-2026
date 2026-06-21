import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_database_error.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
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
    return GpScreen(
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => GpDatabaseError(
          error: error,
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
        data: (db) {
          final repo = LocalPrivacyRepository(db);
          return FutureBuilder<LocalPrivacySnapshot>(
            key: ValueKey(_reload),
            future: repo.snapshot(),
            builder: (context, snapshot) {
              final data = snapshot.data;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  const _PrivacyHeader(),
                  const SizedBox(height: 16),
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
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.download_outlined,
                          iconColor: const Color(0xFF2563EB),
                          backgroundColor: const Color(0xFFDBEAFE),
                          title: 'Daten exportieren',
                          subtitle: 'DSGVO Art. 20',
                          onTap: () => context.go('/export'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.delete_forever_outlined,
                          iconColor: GpColors.emergencyRed,
                          backgroundColor: const Color(0xFFFEE2E2),
                          title: 'Daten löschen',
                          subtitle: 'DSGVO Art. 17',
                          onTap: data == null
                              ? null
                              : () => _confirmClear(repo),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
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
                  ),
                  const SizedBox(height: 16),
                  const _SecurityCard(),
                  const SizedBox(height: 16),
                  _StoredDataCard(snapshot: data),
                  const SizedBox(height: 16),
                  const _RightsCard(),
                  const SizedBox(height: 16),
                  const _PurposeCard(),
                  const SizedBox(height: 16),
                  const _MedicalDisclaimerCard(),
                  const SizedBox(height: 16),
                  const _LocalModeCard(),
                  const SizedBox(height: 16),
                  const _ExportScopeCard(),
                  const SizedBox(height: 16),
                  const _DeleteScopeCard(),
                  const SizedBox(height: 16),
                  const _ContactCard(),
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
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WarningPanel(
                title: 'WARNUNG: Unwiderrufliche Löschung',
                body:
                    'Alle lokalen Gesundheitsdaten, Kontakte, Dokument-Metadaten, Einstellungen und KI-Profile werden permanent von diesem Gerät gelöscht.',
              ),
              SizedBox(height: 12),
              _DialogSection(
                title: 'Betroffen sind:',
                lines: [
                  'Alle medizinischen Einträge',
                  'Notfallkontakte und vorbereitete Nachrichten',
                  'Dokument-Metadaten und lokale Dokumentdateien',
                  'KI-Analysen, Coach-Nachrichten und Empfehlungen',
                  'App-, Datenschutz- und Kommunikations-Einstellungen',
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Nicht betroffen: App-Installation und Betriebssystem-Berechtigungen bleiben bestehen. Sie können die App danach weiter lokal nutzen.',
                style: TextStyle(color: GpColors.textSecondary),
              ),
              SizedBox(height: 10),
              Text(
                'Exportiere die Daten vorher, wenn du eine Sicherung behalten möchtest.',
                style: TextStyle(color: GpColors.textSecondary),
              ),
            ],
          ),
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

class _WarningPanel extends StatelessWidget {
  const _WarningPanel({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GpColors.redSurface,
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  color: GpColors.emergencyRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: GpColors.emergencyRed,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(color: GpColors.redDark, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogSection extends StatelessWidget {
  const _DialogSection({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '• $line',
              style: const TextStyle(
                color: GpColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _PrivacyHeader extends StatelessWidget {
  const _PrivacyHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(GpIcons.shield, color: Color(0xFF2563EB), size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Datenschutz & Sicherheit',
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
          'Ihre Daten sind sicher und geschützt gemäß DSGVO.',
          style: TextStyle(color: GpColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: iconColor.withValues(alpha: 0.25), width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: backgroundColor,
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(
                subtitle,
                style: const TextStyle(
                  color: GpColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.lock_outline,
      iconColor: Color(0xFF16A34A),
      title: 'Ihre Datensicherheit',
      tint: Color(0xFFF0FDF4),
      border: Color(0xFFBBF7D0),
      children: [
        _InfoLine(
          icon: Icons.check_circle,
          iconColor: Color(0xFF16A34A),
          title: 'Lokale Verschlüsselung',
          body:
              'Datenbank und Dokumentdateien werden geschützt auf dem Gerät abgelegt.',
        ),
        _InfoLine(
          icon: Icons.check_circle,
          iconColor: Color(0xFF16A34A),
          title: 'DSGVO-konform',
          body: 'Export, Löschung und KI-Freigabe sind direkt steuerbar.',
        ),
        _InfoLine(
          icon: Icons.check_circle,
          iconColor: Color(0xFF16A34A),
          title: 'Kein Server-Zwang',
          body: 'Der lokale Modus kommt ohne Gesundheitsdaten-Cloud aus.',
        ),
        _InfoLine(
          icon: Icons.check_circle,
          iconColor: Color(0xFF16A34A),
          title: 'Keine Weitergabe',
          body:
              'Native Handoffs öffnen Geräte-Apps, statt Daten zentral zu senden.',
        ),
      ],
    );
  }
}

class _StoredDataCard extends StatelessWidget {
  const _StoredDataCard({required this.snapshot});

  final LocalPrivacySnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.storage_outlined,
      iconColor: const Color(0xFF2563EB),
      title: 'Welche Daten speichern wir?',
      children: [
        _DataGroup(
          title: 'Gesundheitsdaten',
          count: _count([
            'medications',
            'allergies',
            'medical_history_entries',
            'treatment_records',
            'vaccinations',
            'preventive_care_items',
            'blood_pressure_logs',
            'weight_logs',
            'health_passes',
            'health_documents',
          ]),
          bullets: const [
            'Medikamente, Allergien, Diagnosen und Behandlungen',
            'Impfungen, Vorsorge, Termine und Vitalwerte',
            'Gescannte Dokumente und lokale Dokument-Metadaten',
          ],
        ),
        _DataGroup(
          title: 'Notfall- und Kommunikationsdaten',
          count: _count([
            'emergency_contacts',
            'communication_preferences',
            'notifications',
          ]),
          bullets: const [
            'Notfallkontakte und vorbereitete Benachrichtigungen',
            'Telegram-, SMS- und WhatsApp-Handoff-Ziele',
          ],
        ),
        _DataGroup(
          title: 'Einstellungen und KI-Daten',
          count: _count([
            'local_profiles',
            'consent_settings',
            'app_preferences',
            'ai_coach_messages',
          ]),
          bullets: const [
            'Profil, Sprache, Datenschutz- und App-Einstellungen',
            'KI-Coach-Nachrichten und explizite KI-Kontextfreigabe',
          ],
        ),
      ],
    );
  }

  int _count(List<String> tables) {
    final counts = snapshot?.tableCounts;
    if (counts == null) return 0;
    return tables.fold<int>(0, (sum, table) => sum + (counts[table] ?? 0));
  }
}

class _RightsCard extends StatelessWidget {
  const _RightsCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.visibility_outlined,
      iconColor: Color(0xFF7C3AED),
      title: 'Ihre Rechte (DSGVO)',
      children: [
        _InfoLine(
          icon: Icons.info_outline,
          iconColor: Color(0xFF2563EB),
          title: 'Auskunftsrecht (Art. 15)',
          body: 'Sie sehen lokal, welche Datenkategorien gespeichert sind.',
        ),
        _InfoLine(
          icon: Icons.download_outlined,
          iconColor: Color(0xFF16A34A),
          title: 'Datenübertragbarkeit (Art. 20)',
          body: 'Sie können Ihre lokale Gesundheitsakte als JSON exportieren.',
        ),
        _InfoLine(
          icon: Icons.tune_outlined,
          iconColor: Color(0xFFCA8A04),
          title: 'Berichtigungsrecht (Art. 16)',
          body:
              'Einträge können in den jeweiligen Bereichen korrigiert werden.',
        ),
        _InfoLine(
          icon: Icons.delete_forever_outlined,
          iconColor: GpColors.emergencyRed,
          title: 'Löschungsrecht (Art. 17)',
          body:
              'Alle lokalen Daten und Dokumentdateien können gelöscht werden.',
        ),
        _InfoLine(
          icon: Icons.warning_amber_outlined,
          iconColor: Color(0xFFF97316),
          title: 'Widerspruchsrecht (Art. 21)',
          body: 'KI-Kontextfreigabe kann jederzeit deaktiviert werden.',
        ),
      ],
    );
  }
}

class _PurposeCard extends StatelessWidget {
  const _PurposeCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.description_outlined,
      iconColor: Color(0xFF4F46E5),
      title: 'Zweck der Datenverarbeitung',
      children: [
        _PurposeText(
          label: 'Primärzweck',
          body:
              'Bereitstellung einer digitalen Gesundheitsakte zur Verwaltung medizinischer Daten.',
        ),
        _PurposeText(
          label: 'Notfallbenachrichtigung',
          body:
              'Vorbereitung lokaler Handoffs an hinterlegte Kontakte nur auf Ihre Aktion hin.',
        ),
        _PurposeText(
          label: 'KI-Analysen',
          body:
              'Gesundheitskontext wird nur nach expliziter Freigabe für den KI-Coach zusammengefasst.',
        ),
        _PurposeText(
          label: 'Aufbewahrung',
          body:
              'Keine erzwungene Aufbewahrung im lokalen Modus; Sie können Daten vollständig löschen.',
        ),
      ],
    );
  }
}

class _MedicalDisclaimerCard extends StatelessWidget {
  const _MedicalDisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.health_and_safety_outlined,
      iconColor: Color(0xFFCA8A04),
      title: 'Medizinischer Hinweis',
      tint: Color(0xFFFFFBEB),
      border: Color(0xFFFDE68A),
      children: [
        _InfoLine(
          icon: Icons.warning_amber_outlined,
          iconColor: Color(0xFFCA8A04),
          title: 'Keine Diagnose-App',
          body:
              'Gesundheit Plus organisiert lokale Gesundheitsdaten und ersetzt keine ärztliche Diagnose, Behandlung oder Notfallversorgung.',
        ),
        _InfoLine(
          icon: Icons.local_hospital_outlined,
          iconColor: Color(0xFFCA8A04),
          title: 'Bei Beschwerden medizinische Hilfe nutzen',
          body:
              'Bei akuten Beschwerden, Unsicherheit, Nebenwirkungen oder Notfällen wenden Sie sich an medizinisches Fachpersonal oder den örtlichen Notruf.',
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Color(0xFFF9FAFB),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fragen zum Datenschutz?',
              style: TextStyle(
                color: GpColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Nutzen Sie Export und Löschung direkt in der App. Bei Cloud- oder Store-Betrieb müssen Betreiberkontakt und Datenschutzbeauftragter ergänzt werden.',
              style: TextStyle(color: GpColors.textSecondary),
            ),
            SizedBox(height: 10),
            Text(
              'Sie haben das Recht, sich bei einer Datenschutz-Aufsichtsbehörde zu beschweren.',
              style: TextStyle(color: GpColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalModeCard extends StatelessWidget {
  const _LocalModeCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.phone_android_outlined,
      iconColor: Color(0xFF0D9488),
      title: 'Device-only Modus',
      tint: Color(0xFFF0FDFA),
      border: Color(0xFF99F6E4),
      children: [
        _InfoLine(
          icon: Icons.offline_pin_outlined,
          iconColor: Color(0xFF0D9488),
          title: 'Alles lokal auf dem Gerät',
          body:
              'Medikation, Termine, Vitalwerte, Notfalldaten und Einstellungen bleiben im lokalen App-Speicher.',
        ),
        _InfoLine(
          icon: Icons.cloud_off_outlined,
          iconColor: Color(0xFF0D9488),
          title: 'Keine Cloud-Synchronisation',
          body:
              'Im nativen Offline-Modus gibt es keinen Server-Abgleich und keine Account-Pflicht.',
        ),
      ],
    );
  }
}

class _ExportScopeCard extends StatelessWidget {
  const _ExportScopeCard();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.download_outlined,
      iconColor: const Color(0xFF2563EB),
      title: 'Exportumfang',
      children: [
        const _DialogSection(
          title: 'Der JSON-Export enthält:',
          lines: [
            'Profil- und App-Einstellungen',
            'Medizinische Daten wie Medikamente, Allergien und Vitalwerte',
            'Notfallkontakte, Termine und Benachrichtigungen',
            'Dokument-Metadaten ohne externe Cloud-Kopie',
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            border: Border.all(color: const Color(0xFFBFDBFE)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Hinweis: Große Dokumentdateien werden auf dem Gerät verwaltet; der Export beschreibt sie über Metadaten und lokale Pfade.',
              style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteScopeCard extends StatelessWidget {
  const _DeleteScopeCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.delete_forever_outlined,
      iconColor: GpColors.emergencyRed,
      title: 'Löschumfang',
      tint: GpColors.redSurface,
      border: Color(0xFFFECACA),
      children: [
        _InfoLine(
          icon: Icons.delete_sweep_outlined,
          iconColor: GpColors.emergencyRed,
          title: 'Betroffen sind alle lokalen Gesundheitsdaten',
          body:
              'Medizinische Einträge, Notfallkontakte, Dokument-Metadaten, KI-Profile und Einstellungen werden entfernt.',
        ),
        _InfoLine(
          icon: Icons.phone_android_outlined,
          iconColor: Color(0xFF6B7280),
          title: 'Nicht betroffen ist die App-Installation',
          body:
              'Nach der Löschung bleibt die App nutzbar und startet wieder mit leerem lokalen Speicher.',
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
    this.tint,
    this.border,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;
  final Color? tint;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: tint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: border == null
            ? BorderSide.none
            : BorderSide(color: border!, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(
                body,
                style: const TextStyle(
                  color: GpColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DataGroup extends StatelessWidget {
  const _DataGroup({
    required this.title,
    required this.count,
    required this.bullets,
  });

  final String title;
  final int count;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '$count lokal',
              style: const TextStyle(
                color: GpColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final bullet in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '• $bullet',
              style: const TextStyle(
                color: GpColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _PurposeText extends StatelessWidget {
  const _PurposeText({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: GpColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: body,
            style: const TextStyle(color: GpColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
