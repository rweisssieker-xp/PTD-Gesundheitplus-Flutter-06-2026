import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/document_repository.dart';

typedef HealthRecordExporter = Future<File> Function(String exportDirectory);
typedef ExportDirectoryProvider = Future<Directory> Function();
typedef ShareExportFile = Future<void> Function(File file);

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({
    super.key,
    this.exporter,
    this.directoryProvider,
    this.shareFile,
  });

  final HealthRecordExporter? exporter;
  final ExportDirectoryProvider? directoryProvider;
  final ShareExportFile? shareFile;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  File? _exportFile;
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: GpColors.grayDark),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(GpIcons.export, color: Colors.white, size: 46),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Lokale Gesundheitsdaten als JSON-Datei exportieren',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: dbAsync.hasValue && !_working ? _createExport : null,
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Exportdatei erstellen'),
          ),
          if (_exportFile != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Export bereit'),
                subtitle: Text(_exportFile!.path),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _shareExport,
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('Teilen'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createExport() async {
    setState(() => _working = true);
    try {
      final dir =
          await widget.directoryProvider?.call() ??
          await getApplicationDocumentsDirectory();
      final file = widget.exporter != null
          ? await widget.exporter!(dir.path)
          : await DocumentRepository(
              ref.read(appDatabaseProvider).requireValue,
            ).exportHealthRecord(dir.path);
      if (!mounted) return;
      setState(() => _exportFile = file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Export konnte nicht erstellt werden. Bitte Speicherplatz und Berechtigungen prüfen.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _shareExport() async {
    final file = _exportFile;
    if (file == null) return;
    try {
      if (widget.shareFile != null) {
        await widget.shareFile!(file);
      } else {
        await Share.shareXFiles([XFile(file.path)]);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export konnte nicht geteilt werden.')),
      );
    }
  }
}
