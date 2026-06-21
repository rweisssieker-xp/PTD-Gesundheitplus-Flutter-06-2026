import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/platform/permission_service.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/document_repository.dart';
import '../domain/medical_document_insights.dart';
import 'medical_insights_card.dart';

typedef DocumentImagePicker = Future<XFile?> Function(ImageSource source);
typedef DocumentPermissionGate = Future<bool> Function(ImageSource source);

class DocumentScanScreen extends ConsumerStatefulWidget {
  const DocumentScanScreen({
    super.key,
    DocumentImagePicker? imagePicker,
    DocumentPermissionGate? permissionGate,
    Future<bool> Function()? openSettings,
  }) : imagePicker = imagePicker ?? _defaultPickImage,
       permissionGate = permissionGate ?? _defaultPermissionGate,
       openSettings = openSettings ?? _defaultOpenSettings;

  final DocumentImagePicker imagePicker;
  final DocumentPermissionGate permissionGate;
  final Future<bool> Function() openSettings;

  @override
  ConsumerState<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends ConsumerState<DocumentScanScreen> {
  final _title = TextEditingController();
  final _documentDate = TextEditingController();
  final _doctor = TextEditingController();
  final _tags = TextEditingController();
  final _notes = TextEditingController();
  _DocumentType _selectedType = _documentTypes.first;
  var _showAdvanced = false;
  XFile? _picked;
  bool _saving = false;
  String? _permissionMessage;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
        children: [
          _ScanHeader(onOpenDocuments: () => context.go('/documents')),
          const SizedBox(height: 16),
          _DocumentTypePicker(
            selectedType: _selectedType,
            onSelected: (type) {
              setState(() {
                final currentTitle = _title.text.trim();
                final usesDefaultTitle = _documentTypes.any(
                  (knownType) => knownType.defaultTitle == currentTitle,
                );
                _selectedType = type;
                if (currentTitle.isEmpty || usesDefaultTitle) {
                  _title.text = type.defaultTitle;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          _SelectedTypeCard(type: _selectedType),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Titel *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Notizen / erkannter Text',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
            icon: Icon(
              _showAdvanced
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
            label: Text(
              _showAdvanced
                  ? 'Erweiterte Angaben ausblenden'
                  : 'Erweiterte Angaben',
            ),
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _documentDate,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Dokumentdatum',
                hintText: 'TT.MM.JJJJ oder JJJJ-MM-TT',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _doctor,
              decoration: const InputDecoration(
                labelText: 'Behandelnde Praxis / Arzt',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'z.B. Labor, Kontrolle, Hausarzt',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _LocalScanActions(onPick: _pick),
          const SizedBox(height: 16),
          MedicalInsightsCard(
            insights: const MedicalDocumentInsightAnalyzer().analyzeText(
              title: _title.text.trim().isEmpty
                  ? _selectedType.defaultTitle
                  : _title.text.trim(),
              category: _selectedType.label,
              notes: _combinedNotes(),
            ),
          ),
          const SizedBox(height: 16),
          if (_permissionMessage != null) ...[
            _PermissionWarningCard(
              message: _permissionMessage!,
              onOpenSettings: widget.openSettings,
            ),
            const SizedBox(height: 16),
          ],
          if (_picked != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(_picked!.name),
                subtitle: const Text('Bereit zum lokalen Speichern'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: dbAsync.hasValue && !_saving ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Dokument lokal speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    final hasPermission = await widget.permissionGate(source);
    if (!mounted) return;
    if (!hasPermission) {
      setState(() {
        _permissionMessage = source == ImageSource.camera
            ? 'Kamera-Zugriff ist blockiert. Erlauben Sie die Kamera in den Systemeinstellungen, um Dokumente lokal aufzunehmen.'
            : 'Galerie-Zugriff ist blockiert. Erlauben Sie Fotos in den Systemeinstellungen, um Dokumentbilder lokal zu speichern.';
      });
      return;
    }

    final picked = await widget.imagePicker(source);
    if (!mounted) return;
    setState(() {
      _permissionMessage = null;
      if (picked != null) _picked = picked;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _picked == null) return;
    setState(() => _saving = true);
    final db = ref.read(appDatabaseProvider).requireValue;
    final dir = await getApplicationDocumentsDirectory();
    await DocumentRepository(db).addDocument(
      title: title,
      category: _selectedType.label,
      sourcePath: _picked!.path,
      documentsDir: dir.path,
      mimeType: _picked!.mimeType,
      capturedAt: _parseDateInput(_documentDate.text),
      notes: _combinedNotes(),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _picked = null;
      _title.clear();
      _documentDate.clear();
      _doctor.clear();
      _tags.clear();
      _notes.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Dokument lokal gespeichert')));
  }

  @override
  void initState() {
    super.initState();
    _title.text = _selectedType.defaultTitle;
    _title.addListener(_refreshInsightPreview);
    _documentDate.addListener(_refreshInsightPreview);
    _doctor.addListener(_refreshInsightPreview);
    _tags.addListener(_refreshInsightPreview);
    _notes.addListener(_refreshInsightPreview);
  }

  @override
  void dispose() {
    _title.removeListener(_refreshInsightPreview);
    _documentDate.removeListener(_refreshInsightPreview);
    _doctor.removeListener(_refreshInsightPreview);
    _tags.removeListener(_refreshInsightPreview);
    _notes.removeListener(_refreshInsightPreview);
    _title.dispose();
    _documentDate.dispose();
    _doctor.dispose();
    _tags.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _refreshInsightPreview() {
    if (mounted) setState(() {});
  }

  String? _combinedNotes() {
    final parts = [
      _emptyToNull(_notes.text),
      _emptyToNull(_doctor.text) == null
          ? null
          : 'Praxis/Arzt: ${_doctor.text.trim()}',
      _emptyToNull(_tags.text) == null ? null : 'Tags: ${_tags.text.trim()}',
    ].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join('\n');
  }
}

class _DocumentType {
  const _DocumentType({
    required this.label,
    required this.defaultTitle,
    required this.icon,
    required this.colors,
  });

  final String label;
  final String defaultTitle;
  final IconData icon;
  final List<Color> colors;
}

const _documentTypes = [
  _DocumentType(
    label: 'Arztbrief',
    defaultTitle: 'Neuer Arztbrief',
    icon: Icons.local_hospital_outlined,
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
  ),
  _DocumentType(
    label: 'Rezept',
    defaultTitle: 'Neues Rezept',
    icon: Icons.medication_outlined,
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
  ),
  _DocumentType(
    label: 'Laborbefund',
    defaultTitle: 'Neuer Laborbefund',
    icon: Icons.science_outlined,
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  ),
  _DocumentType(
    label: 'Terminkarte',
    defaultTitle: 'Neue Terminkarte',
    icon: Icons.calendar_month_outlined,
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
  ),
  _DocumentType(
    label: 'Impfpass',
    defaultTitle: 'Impfpass-Eintrag',
    icon: Icons.vaccines_outlined,
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
  ),
  _DocumentType(
    label: 'Allergiepass',
    defaultTitle: 'Allergiepass-Eintrag',
    icon: Icons.warning_amber_outlined,
    colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
  ),
];

class _ScanHeader extends StatelessWidget {
  const _ScanHeader({required this.onOpenDocuments});

  final VoidCallback onOpenDocuments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(GpIcons.scan, color: Color(0xFF2563EB), size: 30),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dokument scannen',
                    style: TextStyle(
                      color: GpColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Gesundheitsdokumente lokal aufnehmen und analysieren',
                    style: TextStyle(
                      color: GpColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Gescannte Dokumente anzeigen',
              onPressed: onOpenDocuments,
              icon: const Icon(Icons.folder_open_outlined),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: GpColors.indigo),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(GpIcons.scan, color: Colors.white, size: 44),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Dokument lokal aufnehmen oder aus der Galerie anhaengen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentTypePicker extends StatelessWidget {
  const _DocumentTypePicker({
    required this.selectedType,
    required this.onSelected,
  });

  final _DocumentType selectedType;
  final ValueChanged<_DocumentType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Was möchten Sie scannen?',
              style: TextStyle(
                color: GpColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (final type in _documentTypes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DocumentTypeTile(
                  type: type,
                  selected: type.label == selectedType.label,
                  onTap: () => onSelected(type),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTypeTile extends StatelessWidget {
  const _DocumentTypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final _DocumentType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : GpColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: type.colors),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(type.icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type.label,
                style: const TextStyle(
                  color: GpColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }
}

class _SelectedTypeCard extends StatelessWidget {
  const _SelectedTypeCard({required this.type});

  final _DocumentType type;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF9FAFB),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(type.icon, color: type.colors.first),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Sie scannen: ',
                      style: TextStyle(color: GpColors.textSecondary),
                    ),
                    TextSpan(
                      text: type.label,
                      style: const TextStyle(
                        color: GpColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _LocalBadge(),
          ],
        ),
      ),
    );
  }
}

class _LocalScanActions extends StatelessWidget {
  const _LocalScanActions({required this.onPick});

  final ValueChanged<ImageSource> onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokale Aufnahme',
                    style: TextStyle(
                      color: GpColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Kamera- und Galerieauswahl bleiben auf diesem Gerät. Die Analyse ist regelbasiert lokal.',
              style: TextStyle(color: GpColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onPick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Kamera'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onPick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galerie'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalBadge extends StatelessWidget {
  const _LocalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Lokal',
        style: TextStyle(
          color: Color(0xFF16A34A),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
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

Future<XFile?> _defaultPickImage(ImageSource source) {
  return ImagePicker().pickImage(source: source);
}

Future<bool> _defaultPermissionGate(ImageSource source) {
  const permissions = PermissionService();
  return source == ImageSource.camera
      ? permissions.ensureCamera()
      : permissions.ensurePhotos();
}

Future<bool> _defaultOpenSettings() {
  return const PermissionService().openSystemSettings();
}

class _PermissionWarningCard extends StatelessWidget {
  const _PermissionWarningCard({
    required this.message,
    required this.onOpenSettings,
  });

  final String message;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFFCD34D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Systemeinstellungen öffnen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
