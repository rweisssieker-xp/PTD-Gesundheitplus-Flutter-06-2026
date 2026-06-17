import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _category = TextEditingController(text: 'Befund');
  final _notes = TextEditingController();
  XFile? _picked;
  bool _saving = false;
  String? _permissionMessage;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: GpColors.indigo),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(GpIcons.scan, color: Colors.white, size: 46),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Dokument lokal aufnehmen oder aus der Galerie anhaengen',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Titel *'),
          ),
          TextField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Kategorie'),
          ),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notizen'),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          MedicalInsightsCard(
            insights: const MedicalDocumentInsightAnalyzer().analyzeText(
              title: _title.text.trim().isEmpty
                  ? 'Neues Dokument'
                  : _title.text.trim(),
              category: _emptyToNull(_category.text) ?? 'Dokument',
              notes: _emptyToNull(_notes.text),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Kamera'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galerie'),
              ),
            ],
          ),
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
            label: const Text('Lokal speichern'),
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
      category: _emptyToNull(_category.text) ?? 'Dokument',
      sourcePath: _picked!.path,
      documentsDir: dir.path,
      mimeType: _picked!.mimeType,
      notes: _emptyToNull(_notes.text),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _picked = null;
      _title.clear();
      _notes.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Dokument lokal gespeichert')));
  }

  @override
  void initState() {
    super.initState();
    _title.addListener(_refreshInsightPreview);
    _category.addListener(_refreshInsightPreview);
    _notes.addListener(_refreshInsightPreview);
  }

  @override
  void dispose() {
    _title.removeListener(_refreshInsightPreview);
    _category.removeListener(_refreshInsightPreview);
    _notes.removeListener(_refreshInsightPreview);
    _title.dispose();
    _category.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _refreshInsightPreview() {
    if (mounted) setState(() {});
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
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
