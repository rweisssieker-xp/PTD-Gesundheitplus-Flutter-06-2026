import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/device_contact_import_service.dart';
import '../data/emergency_repository.dart';
import '../domain/device_contact.dart';

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
                  _ContactImportCard(
                    repo: repo,
                    onImported: () => setState(() => _reload++),
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

class _ContactImportCard extends StatefulWidget {
  const _ContactImportCard({required this.repo, required this.onImported});

  final EmergencyRepository repo;
  final VoidCallback onImported;

  @override
  State<_ContactImportCard> createState() => _ContactImportCardState();
}

class _ContactImportCardState extends State<_ContactImportCard> {
  final _service = const DeviceContactImportService();
  final _query = TextEditingController();
  final Set<String> _selected = {};
  List<DeviceContact> _contacts = const [];
  bool _loading = false;
  bool _accessRequested = false;
  bool _accessDenied = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<DeviceContact> get _filteredContacts {
    final needle = _query.text.trim().toLowerCase();
    if (needle.isEmpty) return _contacts;
    return _contacts
        .where(
          (contact) =>
              contact.name.toLowerCase().contains(needle) ||
              contact.phone.toLowerCase().contains(needle),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBFDBFE), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.group_add_outlined, color: Color(0xFF2563EB)),
              title: Text('Kontakte importieren'),
              subtitle: Text(
                'Adressbuchkontakte werden nur nach Zustimmung gelesen und lokal gespeichert.',
              ),
            ),
            if (!_accessRequested) ...[
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFCE8),
                  border: Border.all(color: const Color(0xFFFEF08A)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFFCA8A04),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Es werden nur Kontakte mit Telefonnummer angezeigt. Importierte Kontakte bleiben unverifiziert, bis Sie sie pruefen.',
                          style: TextStyle(
                            color: Color(0xFF713F12),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loading ? null : _loadContacts,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_outlined),
                label: Text(
                  _loading ? 'Lädt...' : 'Zugriff auf Kontakte anfordern',
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Alternative: Kontakte manuell ueber + Kontakt hinzufuegen',
                  style: TextStyle(color: GpColors.textSecondary, fontSize: 12),
                ),
              ),
            ] else if (_accessDenied) ...[
              const SizedBox(height: 8),
              const Text(
                'Kontaktzugriff wurde nicht erlaubt. Sie koennen Kontakte weiterhin manuell anlegen.',
                style: TextStyle(color: GpColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _loadContacts,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Erneut versuchen'),
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextField(
                controller: _query,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_outlined),
                  labelText: 'Kontakte durchsuchen',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              if (_filteredContacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: Text('Keine Kontakte gefunden')),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final selected = _selected.contains(contact.id);
                      return Card(
                        color: selected
                            ? const Color(0xFFEFF6FF)
                            : Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF3B82F6)
                                : GpColors.border,
                            width: 2,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: selected,
                          onChanged: (_) => _toggle(contact.id),
                          secondary: const Icon(Icons.phone_outlined),
                          title: Text(contact.name),
                          subtitle: Text(
                            contact.allPhones.length > 1
                                ? '${contact.phone} (+${contact.allPhones.length - 1} weitere Nummern)'
                                : contact.phone,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _selected.isEmpty || _loading ? null : _import,
                icon: const Icon(Icons.check_circle_outline),
                label: Text('${_selected.length} Kontakt(e) importieren'),
              ),
              const SizedBox(height: 8),
              Text(
                '${_contacts.length} Kontakte gefunden - ${_selected.length} ausgewählt',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _accessRequested = true;
      _accessDenied = false;
    });
    final result = await _service.loadContacts();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _accessDenied = !result.allowed;
      _contacts = result.contacts;
      _selected
        ..clear()
        ..addAll(result.contacts.take(1).map((contact) => contact.id));
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _import() async {
    final contacts = _contacts
        .where((contact) => _selected.contains(contact.id))
        .toList();
    setState(() => _loading = true);
    final imported = await widget.repo.importDeviceContacts(contacts);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _selected.clear();
    });
    widget.onImported();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$imported Kontakt(e) importiert. Bitte anschliessend verifizieren.',
        ),
      ),
    );
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
