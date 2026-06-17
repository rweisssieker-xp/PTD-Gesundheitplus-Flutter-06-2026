import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/care_repository.dart';
import '../domain/care.dart';

class FamilyCircleScreen extends ConsumerStatefulWidget {
  const FamilyCircleScreen({super.key});

  @override
  ConsumerState<FamilyCircleScreen> createState() => _FamilyCircleScreenState();
}

class _FamilyCircleScreenState extends ConsumerState<FamilyCircleScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openMemberEditor(CareRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Person'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = CareRepository(db);
          return FutureBuilder<List<Object>>(
            key: ValueKey(_reload),
            future: Future.wait([
              repo.listFamilyMembers(),
              repo.listCheckIns(),
            ]),
            builder: (context, snapshot) {
              final members =
                  (snapshot.data?.firstOrNull as List<FamilyMember>?) ?? [];
              final checkIns =
                  (snapshot.data?.lastOrNull as List<FamilyCheckIn>?) ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: GpColors.purplePink,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(
                            GpIcons.family,
                            color: Colors.white,
                            size: 46,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${members.length} Personen',
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
                  ...members.map(
                    (member) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(GpIcons.family),
                        title: Text(member.name),
                        subtitle: Text(
                          [
                            member.relationship,
                            member.role,
                            member.phone,
                          ].whereType<String>().join(' • '),
                        ),
                        trailing: IconButton(
                          tooltip: 'Check-in',
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () async {
                            await repo.addCheckIn(
                              memberId: member.id,
                              memberName: member.name,
                              status: 'ok',
                              note: 'Manuell bestaetigt',
                            );
                            if (mounted) setState(() => _reload++);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check-ins',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (checkIns.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Noch keine Check-ins'),
                      ),
                    )
                  else
                    ...checkIns
                        .take(10)
                        .map(
                          (checkIn) => ListTile(
                            leading: const Icon(Icons.done),
                            title: Text(checkIn.memberName),
                            subtitle: Text(
                              '${checkIn.status} • ${_date(checkIn.checkedAt)}',
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

  Future<void> _openMemberEditor(CareRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FamilyMemberEditor(repo: repo),
    );
    if (saved == true) setState(() => _reload++);
  }
}

class _FamilyMemberEditor extends StatefulWidget {
  const _FamilyMemberEditor({required this.repo});

  final CareRepository repo;

  @override
  State<_FamilyMemberEditor> createState() => _FamilyMemberEditorState();
}

class _FamilyMemberEditorState extends State<_FamilyMemberEditor> {
  final _name = TextEditingController();
  final _relationship = TextEditingController();
  final _phone = TextEditingController();
  final _role = TextEditingController(text: 'Kontakt');

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
              'Person hinzufuegen',
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
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
            TextField(
              controller: _role,
              decoration: const InputDecoration(labelText: 'Rolle'),
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
    await widget.repo.addFamilyMember(
      name: name,
      relationship: _emptyToNull(_relationship.text),
      phone: _emptyToNull(_phone.text),
      role: _emptyToNull(_role.text),
    );
    if (mounted) Navigator.pop(context, true);
  }
}

String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
