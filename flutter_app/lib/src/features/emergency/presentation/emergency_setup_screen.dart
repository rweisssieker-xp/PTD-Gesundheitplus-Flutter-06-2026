import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/emergency_repository.dart';

class EmergencySetupScreen extends ConsumerStatefulWidget {
  const EmergencySetupScreen({super.key});

  @override
  ConsumerState<EmergencySetupScreen> createState() =>
      _EmergencySetupScreenState();
}

class _EmergencySetupScreenState extends ConsumerState<EmergencySetupScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openEditor(EmergencyRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Kontakt'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = EmergencyRepository(db);
          return FutureBuilder<List<EmergencyContact>>(
            key: ValueKey(_reload),
            future: repo.listContacts(),
            builder: (context, snapshot) {
              final contacts = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: GpColors.redSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GpColors.emergencyRed),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: ListTile(
                        leading: Icon(
                          GpIcons.emergency,
                          color: GpColors.emergencyRed,
                        ),
                        title: Text('Notfallkontakte lokal'),
                        subtitle: Text(
                          'Kontakte bleiben auf dem Geraet und werden in die Offline-Notfallkarte uebernommen.',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (contacts.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('Noch keine Kontakte')),
                      ),
                    )
                  else
                    ...contacts.map(
                      (contact) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            contact.verified
                                ? Icons.verified_outlined
                                : Icons.person_outline,
                            color: contact.verified
                                ? GpColors.green.first
                                : GpColors.textSecondary,
                          ),
                          title: Text(contact.name),
                          subtitle: Text(
                            [
                              contact.relationship,
                              contact.phone,
                              contact.messenger,
                            ].whereType<String>().join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'verify') {
                                await repo.verifyContact(contact.id);
                              } else if (value == 'delete') {
                                await repo.deleteContact(contact.id);
                              }
                              if (mounted) setState(() => _reload++);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'verify',
                                child: Text('Verifiziert'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Loeschen'),
                              ),
                            ],
                          ),
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

  Future<void> _openEditor(EmergencyRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EmergencyContactEditor(repo: repo),
    );
    if (saved == true) setState(() => _reload++);
  }
}

class _EmergencyContactEditor extends StatefulWidget {
  const _EmergencyContactEditor({required this.repo});

  final EmergencyRepository repo;

  @override
  State<_EmergencyContactEditor> createState() =>
      _EmergencyContactEditorState();
}

class _EmergencyContactEditorState extends State<_EmergencyContactEditor> {
  final _name = TextEditingController();
  final _relationship = TextEditingController();
  final _phone = TextEditingController();
  final _messenger = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notfallkontakt',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            TextField(
              controller: _relationship,
              decoration: const InputDecoration(labelText: 'Beziehung'),
            ),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
            TextField(
              controller: _messenger,
              decoration: const InputDecoration(labelText: 'Messenger'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await widget.repo.addContact(
      name: name,
      relationship: _emptyToNull(_relationship.text),
      phone: _emptyToNull(_phone.text),
      messenger: _emptyToNull(_messenger.text),
    );
    if (mounted) Navigator.pop(context, true);
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
