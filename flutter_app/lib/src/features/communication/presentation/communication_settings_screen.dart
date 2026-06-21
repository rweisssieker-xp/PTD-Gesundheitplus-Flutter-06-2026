import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_handoff_service.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/communication_preferences_repository.dart';

class CommunicationSettingsScreen extends ConsumerStatefulWidget {
  const CommunicationSettingsScreen({
    super.key,
    required this.channel,
    required this.title,
    this.handoff = const PlatformHandoffService(),
  });

  final String channel;
  final String title;
  final PlatformHandoffService handoff;

  @override
  ConsumerState<CommunicationSettingsScreen> createState() =>
      _CommunicationSettingsScreenState();
}

class _CommunicationSettingsScreenState
    extends ConsumerState<CommunicationSettingsScreen> {
  final _displayName = TextEditingController();
  final _target = TextEditingController();
  final _notes = TextEditingController();
  final _message = TextEditingController(
    text: 'Test-Nachricht von Gesundheit Plus',
  );
  bool _enabled = false;
  bool _loaded = false;
  bool _launching = false;

  _ChannelConfig get _config => _ChannelConfig.forChannel(widget.channel);

  @override
  void dispose() {
    _displayName.dispose();
    _target.dispose();
    _notes.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    final config = _config;
    return GpScreen(
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = CommunicationPreferencesRepository(db);
          return FutureBuilder<CommunicationPreference>(
            future: repo.get(widget.channel),
            builder: (context, snapshot) {
              if (snapshot.hasData && !_loaded) {
                final pref = snapshot.data!;
                _enabled = pref.enabled;
                _displayName.text = pref.displayName ?? '';
                _target.text = pref.targetValue ?? '';
                _notes.text = pref.notes ?? '';
                _loaded = true;
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  _Header(config: config),
                  const SizedBox(height: 16),
                  _StatusCard(
                    config: config,
                    enabled: _enabled,
                    target: _target.text,
                    launching: _launching,
                    onTest: _enabled && _target.text.trim().isNotEmpty
                        ? () => _launchChannelTest(context)
                        : null,
                    onDisconnect: _enabled
                        ? () async {
                            setState(() => _enabled = false);
                            await _save(repo, showSnack: false);
                            if (context.mounted) {
                              _snack(
                                context,
                                '${config.shortName} lokal deaktiviert',
                              );
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _BenefitsCard(config: config),
                  const SizedBox(height: 16),
                  if (widget.channel == 'telegram')
                    _TelegramSetupSteps(
                      targetController: _target,
                      onCopy: _copy,
                      onOpenBot: () => _launchTelegramBot(context),
                      onConnect: () => _connectChannel(repo),
                    )
                  else
                    _SmsSetupCard(
                      targetController: _target,
                      messageController: _message,
                      launching: _launching,
                      onSendSms: () => _launchTest(context, sms: true),
                      onSendWhatsApp: () => _launchTest(context, sms: false),
                    ),
                  const SizedBox(height: 16),
                  _LocalSettingsCard(
                    config: config,
                    enabled: _enabled,
                    displayNameController: _displayName,
                    targetController: _target,
                    notesController: _notes,
                    onEnabledChanged: (value) =>
                        setState(() => _enabled = value),
                    onSave: () => _save(repo),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _save(
    CommunicationPreferencesRepository repo, {
    bool showSnack = true,
  }) async {
    await repo.save(
      channel: widget.channel,
      enabled: _enabled,
      displayName: _emptyToNull(_displayName.text),
      targetValue: _emptyToNull(_target.text),
      notes: _emptyToNull(_notes.text),
    );
    if (showSnack && mounted) {
      _snack(context, 'Lokal gespeichert');
    }
  }

  Future<void> _connectChannel(CommunicationPreferencesRepository repo) async {
    if (_target.text.trim().isEmpty) {
      _snack(context, 'Bitte zuerst Telegram-Chat oder Benutzer eintragen');
      return;
    }
    setState(() => _enabled = true);
    await _save(repo, showSnack: false);
    if (mounted) {
      _snack(context, '${_config.shortName} lokal verbunden');
    }
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) _snack(context, 'In Zwischenablage kopiert');
  }

  Future<void> _launchTelegramBot(BuildContext context) async {
    await _launchUri(
      context,
      PlatformHandoffService.telegramUri('GesundheitPlusBot'),
    );
  }

  Future<void> _launchTest(BuildContext context, {required bool sms}) async {
    final target = _target.text.trim();
    if (target.isEmpty) {
      _snack(context, 'Bitte zuerst eine Telefonnummer eintragen');
      return;
    }
    final uri = sms
        ? PlatformHandoffService.smsUri(target, _message.text)
        : PlatformHandoffService.whatsappUri(target, _message.text);
    await _launchUri(context, uri);
  }

  Future<void> _launchChannelTest(BuildContext context) async {
    final target = _target.text.trim();
    if (target.isEmpty) {
      _snack(context, 'Bitte zuerst ein Ziel eintragen');
      return;
    }
    if (widget.channel == 'telegram') {
      await _launchUri(context, PlatformHandoffService.telegramUri(target));
      return;
    }
    await _launchTest(context, sms: true);
  }

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    setState(() => _launching = true);
    final ok = await widget.handoff.launch(uri);
    if (context.mounted) {
      _snack(
        context,
        ok
            ? 'Native App geöffnet'
            : 'Keine passende App auf diesem Gerät gefunden',
      );
    }
    if (mounted) setState(() => _launching = false);
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.config});

  final _ChannelConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(config.icon, color: config.accent, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                config.heading,
                style: const TextStyle(
                  color: GpColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          config.subtitle,
          style: const TextStyle(color: GpColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.config,
    required this.enabled,
    required this.target,
    required this.launching,
    required this.onTest,
    required this.onDisconnect,
  });

  final _ChannelConfig config;
  final bool enabled;
  final String target;
  final bool launching;
  final VoidCallback? onTest;
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Card(
        color: const Color(0xFFEFF6FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFBFDBFE), width: 2),
        ),
        child: ListTile(
          leading: Icon(Icons.info_outline, color: config.accent),
          title: const Text('Noch nicht verbunden'),
          subtitle: const Text('Folgen Sie den Schritten unten.'),
        ),
      );
    }
    return Card(
      color: const Color(0xFFF0FDF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBBF7D0), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${config.shortName} lokal aktiviert',
                    style: const TextStyle(
                      color: Color(0xFF14532D),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            if (target.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${config.targetLabel}: $target',
                style: const TextStyle(color: Color(0xFF15803D)),
              ),
            ],
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: launching ? null : onTest,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Test-Nachricht senden'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: launching ? null : onDisconnect,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Trennen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.config});

  final _ChannelConfig config;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.benefitsTitle,
              style: const TextStyle(
                color: GpColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 12),
            for (final benefit in config.benefits) ...[
              _CheckLine(text: benefit),
              if (benefit != config.benefits.last) const SizedBox(height: 9),
            ],
          ],
        ),
      ),
    );
  }
}

class _TelegramSetupSteps extends StatelessWidget {
  const _TelegramSetupSteps({
    required this.targetController,
    required this.onCopy,
    required this.onOpenBot,
    required this.onConnect,
  });

  final TextEditingController targetController;
  final Future<void> Function(BuildContext context, String text) onCopy;
  final VoidCallback onOpenBot;
  final VoidCallback onConnect;

  static const _botUrl = 'https://t.me/GesundheitPlusBot';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StepCard(
          number: 1,
          active: true,
          title: 'Öffnen Sie den Gesundheit Plus Bot',
          body: 'Starten Sie Telegram direkt auf diesem Gerät.',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onOpenBot,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Bot öffnen'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onCopy(context, _botUrl),
                  icon: const Icon(Icons.copy),
                  label: const Text('Link kopieren'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StepCard(
          number: 2,
          title: 'Starten Sie den Chat',
          body: 'Senden Sie in Telegram den Startbefehl.',
          children: [
            _CommandBox(
              command: '/start',
              onCopy: () => onCopy(context, '/start'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StepCard(
          number: 3,
          title: 'Holen Sie Ihre Chat-ID',
          body:
              'Der Bot zeigt die Chat-ID, wenn Sie den Befehl unten senden. Benutzername oder t.me-Link funktionieren ebenfalls.',
          children: [
            _CommandBox(
              command: '/mychatid',
              onCopy: () => onCopy(context, '/mychatid'),
            ),
            const SizedBox(height: 10),
            const _HintBox(
              text: 'Die Chat-ID sieht z.B. so aus: 123456789 oder -987654321.',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StepCard(
          number: 4,
          active: true,
          title: 'Chat oder Benutzer speichern',
          body:
              'Tragen Sie Ihre Chat-ID, Ihren Telegram-Benutzer, eine t.me-Adresse oder eine Telefonnummer ein und aktivieren Sie den lokalen Handoff.',
          children: [
            TextField(
              controller: targetController,
              decoration: const InputDecoration(
                labelText: 'Telegram Chat-ID / Benutzer / Chat',
                hintText: '123456789, @name, t.me/name oder +49176...',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
              ),
              onPressed: onConnect,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Verbinden'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmsSetupCard extends StatelessWidget {
  const _SmsSetupCard({
    required this.targetController,
    required this.messageController,
    required this.launching,
    required this.onSendSms,
    required this.onSendWhatsApp,
  });

  final TextEditingController targetController;
  final TextEditingController messageController;
  final bool launching;
  final VoidCallback onSendSms;
  final VoidCallback onSendWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.send_outlined,
              iconColor: Color(0xFF16A34A),
              title: 'Integration testen',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefonnummer',
                hintText: '+491512345678 oder 01512345678',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Nachricht'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: launching ? null : onSendSms,
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('SMS testen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                    onPressed: launching ? null : onSendWhatsApp,
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('WhatsApp'),
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

class _LocalSettingsCard extends StatelessWidget {
  const _LocalSettingsCard({
    required this.config,
    required this.enabled,
    required this.displayNameController,
    required this.targetController,
    required this.notesController,
    required this.onEnabledChanged,
    required this.onSave,
  });

  final _ChannelConfig config;
  final bool enabled;
  final TextEditingController displayNameController;
  final TextEditingController targetController;
  final TextEditingController notesController;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: onEnabledChanged,
              title: Text('${config.shortName} verwenden'),
              subtitle: const Text(
                'Speichert nur lokale Device-Handoff-Daten.',
              ),
            ),
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(labelText: 'Anzeigename'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: targetController,
              decoration: InputDecoration(labelText: config.targetLabel),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notizen'),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Lokal speichern'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.body,
    required this.children,
    this.active = false,
  });

  final int number;
  final String title;
  final String body;
  final List<Widget> children;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: active ? const Color(0xFFEFF6FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: active ? const Color(0xFF3B82F6) : GpColors.border,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF3B82F6),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: GpColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(color: GpColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandBox extends StatelessWidget {
  const _CommandBox({required this.command, required this.onCopy});

  final String command;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              command,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Kopieren',
            onPressed: onCopy,
            icon: const Icon(Icons.copy, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        border: Border.all(color: const Color(0xFFFEF08A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFCA8A04), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFF713F12), fontSize: 12),
              ),
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

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: GpColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _ChannelConfig {
  const _ChannelConfig({
    required this.heading,
    required this.shortName,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.targetLabel,
    required this.benefitsTitle,
    required this.benefits,
  });

  factory _ChannelConfig.forChannel(String channel) {
    if (channel == 'telegram') {
      return const _ChannelConfig(
        heading: 'Telegram-Benachrichtigungen',
        shortName: 'Telegram',
        subtitle:
            'Verbinden Sie Telegram für sofortige Notfall-Benachrichtigungen.',
        icon: GpIcons.chat,
        accent: Color(0xFF3B82F6),
        targetLabel: 'Telegram Benutzer / Chat',
        benefitsTitle: 'Vorteile von Telegram-Benachrichtigungen',
        benefits: [
          'Sofortige Zustellung über die Telegram-App',
          'Kostenlos und ohne SMS-Gebühren',
          'Direkter Handoff an Benutzer, Telefonnummer oder t.me-Link',
          'Lokale Speicherung ohne Cloud-Zwang',
        ],
      );
    }
    return const _ChannelConfig(
      heading: 'SMS & WhatsApp Setup',
      shortName: 'SMS',
      subtitle: 'Testen Sie lokale SMS- und WhatsApp-Handoffs vom Gerät.',
      icon: Icons.sms_outlined,
      accent: GpColors.emergencyRed,
      targetLabel: 'Telefonnummer',
      benefitsTitle: 'Lokale Notfall-Kommunikation',
      benefits: [
        'Native SMS-App wird mit vorbereitetem Text geöffnet',
        'WhatsApp-Handoff nutzt die installierte App auf dem Gerät',
        'Keine Twilio-Secrets oder Server-Abhängigkeit nötig',
        'Telefonnummern bleiben lokal auf dem Gerät gespeichert',
      ],
    );
  }

  final String heading;
  final String shortName;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String targetLabel;
  final String benefitsTitle;
  final List<String> benefits;
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
