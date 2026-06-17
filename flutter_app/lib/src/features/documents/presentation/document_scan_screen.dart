import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../data/document_repository.dart';

class DocumentScanScreen extends ConsumerStatefulWidget {
  const DocumentScanScreen({super.key});

  @override
  ConsumerState<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends ConsumerState<DocumentScanScreen> {
  final _title = TextEditingController();
  final _category = TextEditingController(text: 'Befund');
  final _notes = TextEditingController();
  XFile? _picked;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dokumenten-Scan')),
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
          ),
          const SizedBox(height: 16),
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
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) setState(() => _picked = picked);
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
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
