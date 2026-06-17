import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../../../shared_ui/gp_voice_navigation.dart';
import '../data/appointment_repository.dart';
import '../domain/healthcare_professional.dart';
import '../domain/healthcare_professional_directory.dart';

class HealthcareProfessionalsScreen extends ConsumerStatefulWidget {
  const HealthcareProfessionalsScreen({super.key});

  @override
  ConsumerState<HealthcareProfessionalsScreen> createState() =>
      _HealthcareProfessionalsScreenState();
}

class _HealthcareProfessionalsScreenState
    extends ConsumerState<HealthcareProfessionalsScreen> {
  final _directory = const HealthcareProfessionalDirectory();
  final _directorySearch = TextEditingController();
  var _directoryQuery = '';
  int _reload = 0;

  @override
  void dispose() {
    _directorySearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
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
                  const SizedBox(height: 12),
                  GpVoiceNavigation(
                    content: _professionalsVoiceContent(professionals),
                  ),
                  const SizedBox(height: 16),
                  _DoctorSearchCard(
                    controller: _directorySearch,
                    query: _directoryQuery,
                    results: _directory.search(_directoryQuery),
                    onChanged: (value) =>
                        setState(() => _directoryQuery = value),
                    onAdd: (suggestion) =>
                        _addSuggestedProfessional(repo, suggestion),
                  ),
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

  Future<void> _addSuggestedProfessional(
    AppointmentRepository repo,
    HealthcareProfessionalSuggestion suggestion,
  ) async {
    final existing = await repo.listProfessionals();
    final alreadySaved = existing.any(
      (item) =>
          item.name.toLowerCase() == suggestion.name.toLowerCase() &&
          item.specialty.toLowerCase() == suggestion.specialty.toLowerCase(),
    );
    if (alreadySaved) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dieser Behandler ist bereits gespeichert'),
        ),
      );
      return;
    }
    await repo.saveProfessional(
      repo.newProfessional(
        name: suggestion.name,
        specialty: suggestion.specialty,
        address: suggestion.address,
        phone: suggestion.phone,
        notes: suggestion.notes,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${suggestion.name} übernommen')));
    _refresh();
  }
}

String _professionalsVoiceContent(List<HealthcareProfessional> professionals) {
  if (professionals.isEmpty) {
    return 'Heilberufe. Es sind noch keine Ärzte oder Behandler gespeichert.';
  }
  final details = professionals
      .take(8)
      .map(
        (item) =>
            '${item.name}, ${item.specialty}'
            '${item.phone == null || item.phone!.isEmpty ? '' : ', Telefon ${item.phone}'}',
      )
      .join('. ');
  return 'Heilberufe. ${professionals.length} Behandler gespeichert. $details.';
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

class _DoctorSearchCard extends StatelessWidget {
  const _DoctorSearchCard({
    required this.controller,
    required this.query,
    required this.results,
    required this.onChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String query;
  final List<HealthcareProfessionalSuggestion> results;
  final ValueChanged<String> onChanged;
  final ValueChanged<HealthcareProfessionalSuggestion> onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF0FDF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBFDBFE), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.search, color: Color(0xFF166534)),
                SizedBox(width: 8),
                Text(
                  'Facharzt-Suche',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'z.B. Kardiologe, Orthopäde...',
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Suche löschen',
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.navigation_outlined, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lokale Vorlagen. Keine Standort- oder Internetanfrage.',
                    style: TextStyle(
                      color: GpColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              query.trim().isEmpty
                  ? 'Vorschläge:'
                  : '${results.length} Ergebnisse:',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: GpColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Keine passende lokale Vorlage gefunden.'),
              )
            else
              for (final suggestion in results)
                _DoctorSuggestionTile(
                  suggestion: suggestion,
                  onAdd: () => onAdd(suggestion),
                ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                border: Border.all(color: const Color(0xFFBFDBFE)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tipp: Suche nach Fachrichtung, Beschwerden oder Ort. Die Daten bleiben auf diesem Gerät.',
                style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorSuggestionTile extends StatelessWidget {
  const _DoctorSuggestionTile({required this.suggestion, required this.onAdd});

  final HealthcareProfessionalSuggestion suggestion;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        suggestion.specialty,
                        style: const TextStyle(color: GpColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (suggestion.distanceHint != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        suggestion.distanceHint!,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _SuggestionDetail(
              icon: Icons.place_outlined,
              text: suggestion.address,
            ),
            _SuggestionDetail(
              icon: Icons.phone_outlined,
              text: suggestion.phone,
            ),
            if (suggestion.openingHours.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  suggestion.openingHours,
                  style: const TextStyle(
                    color: GpColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Zu meinen Behandlern hinzufügen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionDetail extends StatelessWidget {
  const _SuggestionDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: GpColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(text)),
        ],
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
