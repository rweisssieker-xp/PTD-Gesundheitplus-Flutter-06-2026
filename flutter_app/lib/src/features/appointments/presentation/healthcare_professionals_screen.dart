import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_handoff_service.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../../../shared_ui/gp_voice_navigation.dart';
import '../data/appointment_repository.dart';
import '../domain/healthcare_professional.dart';
import '../domain/healthcare_professional_directory.dart';
import '../domain/healthcare_professional_text_parser.dart';

class HealthcareProfessionalsScreen extends ConsumerStatefulWidget {
  const HealthcareProfessionalsScreen({super.key});

  @override
  ConsumerState<HealthcareProfessionalsScreen> createState() =>
      _HealthcareProfessionalsScreenState();
}

class _HealthcareProfessionalsScreenState
    extends ConsumerState<HealthcareProfessionalsScreen> {
  final _directory = const HealthcareProfessionalDirectory();
  final _listSearch = TextEditingController();
  final _directorySearch = TextEditingController();
  final _assistantText = TextEditingController();
  HealthcareProfessionalTextSuggestion? _assistantSuggestion;
  String? _assistantError;
  var _listQuery = '';
  var _directoryQuery = '';
  int _reload = 0;

  @override
  void dispose() {
    _listSearch.dispose();
    _directorySearch.dispose();
    _assistantText.dispose();
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
              final filteredProfessionals = _filterProfessionals(
                professionals,
                _listQuery,
              );
              final groupedProfessionals = _groupProfessionals(
                filteredProfessionals,
              );
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                children: [
                  _ProfessionalHeader(
                    count: professionals.length,
                    specialties: _specialtyCount(professionals),
                    withContact: _contactableCount(professionals),
                  ),
                  const SizedBox(height: 12),
                  GpVoiceNavigation(
                    content: _professionalsVoiceContent(professionals),
                  ),
                  const SizedBox(height: 16),
                  _ProfessionalSearchFilterCard(
                    controller: _listSearch,
                    query: _listQuery,
                    resultCount: filteredProfessionals.length,
                    onChanged: (value) => setState(() => _listQuery = value),
                  ),
                  const SizedBox(height: 16),
                  _ProfessionalTextAssistantCard(
                    controller: _assistantText,
                    suggestion: _assistantSuggestion,
                    error: _assistantError,
                    onParse: _parseAssistantText,
                    onSave: _assistantSuggestion?.isComplete == true
                        ? () => _saveAssistantSuggestion(repo)
                        : null,
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
                  else if (filteredProfessionals.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('Keine Behandler für diese Suche'),
                        ),
                      ),
                    )
                  else
                    for (final entry in groupedProfessionals.entries) ...[
                      _SpecialtyGroupHeader(
                        specialty: entry.key,
                        count: entry.value.length,
                      ),
                      const SizedBox(height: 8),
                      for (final item in entry.value)
                        _ProfessionalCard(
                          item: item,
                          onDelete: () async {
                            await repo.deleteProfessional(item.id);
                            _refresh();
                          },
                        ),
                      const SizedBox(height: 8),
                    ],
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

  void _parseAssistantText() {
    final input = _assistantText.text.trim();
    if (input.isEmpty) {
      setState(() {
        _assistantSuggestion = null;
        _assistantError = 'Bitte beschreiben Sie den Behandler zuerst.';
      });
      return;
    }
    final suggestion = const HealthcareProfessionalTextParser().parse(input);
    setState(() {
      _assistantSuggestion = suggestion;
      _assistantError = suggestion.isComplete
          ? null
          : 'Fehlt noch: ${suggestion.missingFields.join(', ')}';
    });
  }

  Future<void> _saveAssistantSuggestion(AppointmentRepository repo) async {
    final suggestion = _assistantSuggestion;
    if (suggestion == null || !suggestion.isComplete) {
      _parseAssistantText();
      return;
    }
    await repo.saveProfessional(
      repo.newProfessional(
        name: suggestion.name!.trim(),
        specialty: suggestion.specialty!.trim(),
        address: suggestion.address,
        phone: suggestion.phone,
        email: suggestion.email,
        notes: 'Aus lokaler Texteingabe erstellt: ${suggestion.originalText}',
      ),
    );
    if (!mounted) return;
    _assistantText.clear();
    setState(() {
      _assistantSuggestion = null;
      _assistantError = null;
      _reload++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Behandler aus Texteingabe gespeichert.')),
    );
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

List<HealthcareProfessional> _filterProfessionals(
  List<HealthcareProfessional> professionals,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return professionals;
  return professionals.where((item) {
    final haystack = [
      item.name,
      item.specialty,
      item.address,
      item.phone,
      item.email,
      item.notes,
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(normalized);
  }).toList();
}

Map<String, List<HealthcareProfessional>> _groupProfessionals(
  List<HealthcareProfessional> professionals,
) {
  final grouped = <String, List<HealthcareProfessional>>{};
  for (final item in professionals) {
    grouped.putIfAbsent(item.specialty, () => []).add(item);
  }
  return grouped;
}

int _specialtyCount(List<HealthcareProfessional> professionals) =>
    professionals.map((item) => item.specialty).toSet().length;

int _contactableCount(List<HealthcareProfessional> professionals) =>
    professionals.where((item) {
      return (item.phone ?? '').trim().isNotEmpty ||
          (item.email ?? '').trim().isNotEmpty;
    }).length;

class _ProfessionalHeader extends StatelessWidget {
  const _ProfessionalHeader({
    required this.count,
    required this.specialties,
    required this.withContact,
  });

  final int count;
  final int specialties;
  final int withContact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(GpIcons.healthcare, color: Color(0xFF16A34A), size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heilberufe',
                    style: TextStyle(
                      color: GpColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Ihre Aerzte und Behandler',
                    style: TextStyle(
                      color: GpColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: GpColors.green),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(GpIcons.healthcare, color: Colors.white, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '$count Behandler gespeichert',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ProfessionalStatTile(
                icon: Icons.local_hospital_outlined,
                value: '$specialties',
                label: 'Fachrichtungen',
                color: const Color(0xFF16A34A),
                background: const Color(0xFFF0FDF4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ProfessionalStatTile(
                icon: Icons.call_outlined,
                value: '$withContact',
                label: 'Kontaktbereit',
                color: const Color(0xFF2563EB),
                background: const Color(0xFFEFF6FF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfessionalStatTile extends StatelessWidget {
  const _ProfessionalStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalSearchFilterCard extends StatelessWidget {
  const _ProfessionalSearchFilterCard({
    required this.controller,
    required this.query,
    required this.resultCount,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String query;
  final int resultCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.search, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Meine Behandler durchsuchen',
                    style: TextStyle(
                      color: GpColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('professional-list-search'),
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Name, Fachrichtung, Ort oder Kontakt suchen',
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Suche loeschen',
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.trim().isEmpty
                  ? 'Alle gespeicherten Behandler'
                  : '$resultCount Treffer lokal gefunden',
              style: const TextStyle(
                color: GpColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialtyGroupHeader extends StatelessWidget {
  const _SpecialtyGroupHeader({required this.specialty, required this.count});

  final String specialty;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            specialty,
            style: const TextStyle(
              color: GpColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _SoftCountBadge(label: '$count'),
      ],
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({required this.item, required this.onDelete});

  final HealthcareProfessional item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final address = item.address?.trim();
    final phone = item.phone?.trim();
    final email = item.email?.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(GpIcons.healthcare, color: Color(0xFF16A34A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: GpColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item.specialty,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Entfernen',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (address != null && address.isNotEmpty)
              _ProfessionalInfoLine(icon: Icons.place_outlined, text: address),
            if (phone != null && phone.isNotEmpty)
              _ProfessionalInfoLine(icon: Icons.phone_outlined, text: phone),
            if (email != null && email.isNotEmpty)
              _ProfessionalInfoLine(icon: Icons.email_outlined, text: email),
            if (item.treatingSince != null)
              _ProfessionalInfoLine(
                icon: Icons.calendar_month_outlined,
                text: 'In Behandlung seit ${_date(item.treatingSince!)}',
              ),
            if ((item.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.notes!.trim(),
                style: const TextStyle(
                  color: GpColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            if ((phone ?? '').isNotEmpty ||
                (email ?? '').isNotEmpty ||
                (address ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ((phone ?? '').isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _launchOrSnack(
                        context,
                        PlatformHandoffService.telUri(phone!),
                        'Telefon-App konnte nicht geoeffnet werden.',
                      ),
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: const Text('Anrufen'),
                    ),
                  if ((email ?? '').isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _launchOrSnack(
                        context,
                        Uri(scheme: 'mailto', path: email),
                        'E-Mail-App konnte nicht geoeffnet werden.',
                      ),
                      icon: const Icon(Icons.email_outlined, size: 18),
                      label: const Text('E-Mail'),
                    ),
                  if ((address ?? '').isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _launchOrSnack(
                        context,
                        Uri(
                          scheme: 'geo',
                          path: '0,0',
                          queryParameters: {'q': address},
                        ),
                        'Karten-App konnte nicht geoeffnet werden.',
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Karte'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfessionalInfoLine extends StatelessWidget {
  const _ProfessionalInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: GpColors.textSecondary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: GpColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCountBadge extends StatelessWidget {
  const _SoftCountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Future<void> _launchOrSnack(
  BuildContext context,
  Uri uri,
  String failureMessage,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final launched = await const PlatformHandoffService().launch(uri);
  if (!launched) {
    messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}

class _ProfessionalTextAssistantCard extends StatelessWidget {
  const _ProfessionalTextAssistantCard({
    required this.controller,
    required this.suggestion,
    required this.error,
    required this.onParse,
    required this.onSave,
  });

  final TextEditingController controller;
  final HealthcareProfessionalTextSuggestion? suggestion;
  final String? error;
  final VoidCallback onParse;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF0FDF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBBF7D0), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.mic_outlined, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokale Behandler-Eingabe',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Beschreiben Sie Name, Fachrichtung und Kontaktdaten wie gesprochen. Die App erkennt die Daten direkt auf dem Gerät.',
              style: TextStyle(color: GpColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Behandler beschreiben',
                hintText:
                    'Dr. Schmidt Kardiologe in Hauptstrasse 4 Telefon 030 123456',
                border: OutlineInputBorder(),
              ),
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 12),
              _ProfessionalSuggestionPreview(suggestion: suggestion!),
            ],
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: const TextStyle(
                  color: GpColors.emergencyRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onParse,
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    label: const Text('Erkennen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.check),
                    label: const Text('Speichern'),
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

class _ProfessionalSuggestionPreview extends StatelessWidget {
  const _ProfessionalSuggestionPreview({required this.suggestion});

  final HealthcareProfessionalTextSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: GpColors.border, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Erkannter Vorschlag',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _ParsedProfessionalLine(
              icon: Icons.person_outline,
              label: suggestion.name ?? 'Name fehlt',
            ),
            _ParsedProfessionalLine(
              icon: Icons.local_hospital_outlined,
              label: suggestion.specialty ?? 'Fachrichtung fehlt',
            ),
            if ((suggestion.address ?? '').isNotEmpty)
              _ParsedProfessionalLine(
                icon: Icons.place_outlined,
                label: suggestion.address!,
              ),
            if ((suggestion.phone ?? '').isNotEmpty)
              _ParsedProfessionalLine(
                icon: Icons.phone_outlined,
                label: suggestion.phone!,
              ),
            if ((suggestion.email ?? '').isNotEmpty)
              _ParsedProfessionalLine(
                icon: Icons.email_outlined,
                label: suggestion.email!,
              ),
          ],
        ),
      ),
    );
  }
}

class _ParsedProfessionalLine extends StatelessWidget {
  const _ParsedProfessionalLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 17, color: GpColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(label)),
        ],
      ),
    );
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

String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';

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
  final _treatingSince = TextEditingController();
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
              controller: _treatingSince,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'In Behandlung seit',
                hintText: 'TT.MM.JJJJ oder JJJJ-MM-TT',
              ),
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
        treatingSince: _parseDateInput(_treatingSince.text),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }
}

DateTime? _parseDateInput(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final iso = DateTime.tryParse(trimmed);
  if (iso != null) return iso;
  final match = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(trimmed);
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  return DateTime(year, month, day);
}
