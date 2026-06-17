import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/app_lock_service.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../privacy/data/local_privacy_repository.dart';
import '../data/local_profile_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _pin = TextEditingController();
  bool _aiConsent = false;
  bool _saved = false;
  final _lock = AppLockService(store: SecureStorageSecretStore());

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: GpColors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Lokales Profil, PIN und KI-Freigabe einrichten',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name *'),
          ),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Gesundheitsnotizen'),
          ),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: '6-stellige PIN'),
          ),
          SwitchListTile(
            value: _aiConsent,
            onChanged: (value) => setState(() => _aiConsent = value),
            title: const Text('KI-Kontext freigeben'),
            subtitle: const Text(
              'Kann spaeter im Datenschutz geaendert werden.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: dbAsync.hasValue ? _save : null,
            icon: const Icon(Icons.check),
            label: const Text('Einrichtung speichern'),
          ),
          if (_saved) ...[
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.verified_user_outlined),
                title: Text('Einrichtung gespeichert'),
                subtitle: Text(
                  'Profil, PIN und Consent wurden lokal gesichert.',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (_pin.text.isNotEmpty) {
      await _lock.setPin(_pin.text);
    }
    final db = ref.read(appDatabaseProvider).requireValue;
    await LocalProfileRepository(
      db,
    ).saveProfile(fullName: name, notes: _emptyToNull(_notes.text));
    await LocalPrivacyRepository(db).setAiContextAllowed(_aiConsent);
    if (mounted) setState(() => _saved = true);
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
