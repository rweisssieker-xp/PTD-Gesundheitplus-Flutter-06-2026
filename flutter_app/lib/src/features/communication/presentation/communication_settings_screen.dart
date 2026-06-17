import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/communication_preferences_repository.dart';

class CommunicationSettingsScreen extends ConsumerStatefulWidget {
  const CommunicationSettingsScreen({
    super.key,
    required this.channel,
    required this.title,
  });

  final String channel;
  final String title;

  @override
  ConsumerState<CommunicationSettingsScreen> createState() =>
      _CommunicationSettingsScreenState();
}

class _CommunicationSettingsScreenState
    extends ConsumerState<CommunicationSettingsScreen> {
  final _displayName = TextEditingController();
  final _target = TextEditingController();
  final _notes = TextEditingController();
  bool _enabled = false;
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
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
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: SwitchListTile(
                      value: _enabled,
                      onChanged: (value) => setState(() => _enabled = value),
                      title: Text('${widget.title} verwenden'),
                      subtitle: const Text(
                        'Speichert nur die lokale Handoff-Praeferenz.',
                      ),
                    ),
                  ),
                  TextField(
                    controller: _displayName,
                    decoration: const InputDecoration(labelText: 'Anzeigename'),
                  ),
                  TextField(
                    controller: _target,
                    decoration: InputDecoration(
                      labelText: widget.channel == 'sms'
                          ? 'Telefonnummer'
                          : 'Telegram Benutzer / Chat',
                    ),
                  ),
                  TextField(
                    controller: _notes,
                    decoration: const InputDecoration(labelText: 'Notizen'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      await repo.save(
                        channel: widget.channel,
                        enabled: _enabled,
                        displayName: _emptyToNull(_displayName.text),
                        targetValue: _emptyToNull(_target.text),
                        notes: _emptyToNull(_notes.text),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lokal gespeichert')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Speichern'),
                  ),
                  const SizedBox(height: 12),
                  const Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.phone_android_outlined,
                        color: GpColors.emergencyRed,
                      ),
                      title: Text('Kein Backend-Zwang'),
                      subtitle: Text(
                        'Nachrichten werden ueber native Device-Funktionen vorbereitet.',
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

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
