import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/document_repository.dart';
import '../domain/health_document.dart';
import '../domain/medical_document_insights.dart';
import 'medical_insights_card.dart';

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
    return GpScreen(
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
                        child: ExpansionTile(
                          leading: _DocumentThumb(repo: repo, document: doc),
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
                          childrenPadding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            12,
                          ),
                          children: [
                            MedicalInsightsCard(
                              insights: const MedicalDocumentInsightAnalyzer()
                                  .analyzeDocument(doc),
                            ),
                          ],
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
  const _DocumentThumb({required this.repo, required this.document});

  final DocumentRepository repo;
  final HealthDocument document;

  @override
  Widget build(BuildContext context) {
    final mimeType = document.mimeType ?? '';
    if (!mimeType.startsWith('image/')) {
      return const Icon(GpIcons.scan, color: GpColors.textSecondary);
    }
    return FutureBuilder<List<int>>(
      future: repo.readDocumentBytes(document),
      builder: (context, snapshot) {
        final bytes = snapshot.data ?? const [];
        if (bytes.isEmpty) {
          return const Icon(GpIcons.scan, color: GpColors.textSecondary);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            Uint8List.fromList(bytes),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(GpIcons.scan, color: GpColors.textSecondary),
          ),
        );
      },
    );
  }
}

String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';
