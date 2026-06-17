import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../data/document_repository.dart';
import '../domain/health_document.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Gescannte Dokumente')),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = DocumentRepository(db);
          return FutureBuilder<List<HealthDocument>>(
            key: ValueKey(_reload),
            future: repo.listDocuments(),
            builder: (context, snapshot) {
              final docs = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (docs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('Noch keine Dokumente')),
                      ),
                    )
                  else
                    ...docs.map(
                      (doc) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: _DocumentThumb(path: doc.localPath),
                          title: Text(doc.title),
                          subtitle: Text(
                            '${doc.category} • ${_date(doc.capturedAt)}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Loeschen',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await repo.deleteDocument(doc.id);
                              if (mounted) setState(() => _reload++);
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
}

class _DocumentThumb extends StatelessWidget {
  const _DocumentThumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (file.existsSync() && file.lengthSync() > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(file, width: 44, height: 44, fit: BoxFit.cover),
      );
    }
    return const Icon(GpIcons.scan, color: GpColors.textSecondary);
  }
}

String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';
