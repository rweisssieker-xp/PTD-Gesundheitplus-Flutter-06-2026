import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../data/appointment_repository.dart';
import '../domain/healthcare_professional.dart';

class HealthcareProfessionalsScreen extends ConsumerStatefulWidget {
  const HealthcareProfessionalsScreen({super.key});

  @override
  ConsumerState<HealthcareProfessionalsScreen> createState() =>
      _HealthcareProfessionalsScreenState();
}

class _HealthcareProfessionalsScreenState
    extends ConsumerState<HealthcareProfessionalsScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Heilberufe')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openEditor(AppointmentRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Behandler'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = AppointmentRepository(db);
          return FutureBuilder<List<HealthcareProfessional>>(
            key: ValueKey(_reload),
            future: repo.listProfessionals(),
            builder: (context, snapshot) {
              final professionals = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfessionalSummary(count: professionals.length),
                  const SizedBox(height: 16),
                  if (professionals.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: Text(
                            'Noch keine Aerzte oder Behandler gespeichert',
                          ),
                        ),
                      ),
                    )
                  else
                    ...professionals.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFDCFCE7),
                            child: Icon(
                              GpIcons.healthcare,
                              color: Colors.green,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            [item.specialty, item.phone, item.email]
                                .whereType<String>()
                                .where((value) => value.isNotEmpty)
                                .join('\n'),
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await repo.deleteProfessional(item.id);
                              _refresh();
                            },
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

  Future<void> _openEditor(AppointmentRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProfessionalEditor(repo: repo),
    );
    if (saved == true) _refresh();
  }

  void _refresh() {
    setState(() {
      _reload++;
    });
  }
}

class _ProfessionalSummary extends StatelessWidget {
  const _ProfessionalSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: GpColors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(GpIcons.healthcare, color: Colors.white, size: 46),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gespeicherte Behandler',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
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

class _ProfessionalEditor extends StatefulWidget {
  const _ProfessionalEditor({required this.repo});

  final AppointmentRepository repo;

  @override
  State<_ProfessionalEditor> createState() => _ProfessionalEditorState();
}

class _ProfessionalEditorState extends State<_ProfessionalEditor> {
  final _name = TextEditingController();
  final _specialty = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();

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
              'Neuer Behandler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            TextField(
              controller: _specialty,
              decoration: const InputDecoration(labelText: 'Fachrichtung *'),
            ),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-Mail'),
            ),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notizen'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _specialty.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Name und Fachrichtung eingeben')),
      );
      return;
    }
    await widget.repo.saveProfessional(
      widget.repo.newProfessional(
        name: _name.text.trim(),
        specialty: _specialty.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }
}
