import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _search = TextEditingController();
  var _query = '';
  var _categoryFilter = 'Alle';
  var _urgencyFilter = 'Alle';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
              final analyzer = const MedicalDocumentInsightAnalyzer();
              final entries = docs
                  .map(
                    (doc) => _DocumentEntry(
                      document: doc,
                      insights: analyzer.analyzeDocument(doc),
                    ),
                  )
                  .toList();
              final categories = [
                'Alle',
                ...{for (final doc in docs) doc.category},
              ];
              final filtered = _filterEntries(
                entries,
                query: _query,
                category: _categoryFilter,
                urgency: _urgencyFilter,
              );
              final attentionCount = entries
                  .where((entry) => entry.insights.requiresAttention)
                  .length;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                children: [
                  _DocumentsHeader(
                    total: docs.length,
                    attention: attentionCount,
                    categories: categories.length - 1,
                    onScan: () => context.go('/documents/scan'),
                  ),
                  const SizedBox(height: 16),
                  if (attentionCount > 0) ...[
                    _AttentionCard(count: attentionCount),
                    const SizedBox(height: 16),
                  ],
                  _DocumentFilterCard(
                    controller: _search,
                    query: _query,
                    categories: categories,
                    selectedCategory: _categoryFilter,
                    selectedUrgency: _urgencyFilter,
                    resultCount: filtered.length,
                    onQueryChanged: (value) => setState(() => _query = value),
                    onCategoryChanged: (value) =>
                        setState(() => _categoryFilter = value),
                    onUrgencyChanged: (value) =>
                        setState(() => _urgencyFilter = value),
                  ),
                  const SizedBox(height: 16),
                  if (docs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('Noch keine Dokumente')),
                      ),
                    )
                  else if (filtered.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('Keine Dokumente für diese Filter'),
                        ),
                      ),
                    )
                  else
                    ...filtered.map(
                      (entry) => _DocumentCard(
                        repo: repo,
                        entry: entry,
                        onDelete: () async {
                          await repo.deleteDocument(entry.document.id);
                          if (mounted) setState(() => _reload++);
                        },
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

class _DocumentEntry {
  const _DocumentEntry({required this.document, required this.insights});

  final HealthDocument document;
  final MedicalDocumentInsights insights;
}

List<_DocumentEntry> _filterEntries(
  List<_DocumentEntry> entries, {
  required String query,
  required String category,
  required String urgency,
}) {
  final normalized = query.trim().toLowerCase();
  return entries.where((entry) {
    final doc = entry.document;
    final matchesQuery =
        normalized.isEmpty ||
        [
          doc.title,
          doc.category,
          doc.notes,
          entry.insights.summary,
          ...entry.insights.findings,
          ...entry.insights.entities.map((entity) => entity.label),
          ...entry.insights.actions.map((action) => action.label),
        ].whereType<String>().join(' ').toLowerCase().contains(normalized);
    final matchesCategory = category == 'Alle' || doc.category == category;
    final matchesUrgency =
        urgency == 'Alle' || entry.insights.urgency.label == urgency;
    return matchesQuery && matchesCategory && matchesUrgency;
  }).toList();
}

class _DocumentsHeader extends StatelessWidget {
  const _DocumentsHeader({
    required this.total,
    required this.attention,
    required this.categories,
    required this.onScan,
  });

  final int total;
  final int attention;
  final int categories;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(GpIcons.scan, color: Color(0xFF2563EB), size: 30),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gescannte Dokumente',
                    style: TextStyle(
                      color: GpColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Lokal gespeicherte Gesundheitsdokumente',
                    style: TextStyle(
                      color: GpColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              tooltip: 'Neu scannen',
              onPressed: onScan,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _DocStatTile(
                icon: Icons.file_present_outlined,
                value: '$total',
                label: 'Dokumente',
                color: const Color(0xFF2563EB),
                background: const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DocStatTile(
                icon: Icons.warning_amber_outlined,
                value: '$attention',
                label: 'Aufmerksamkeit',
                color: GpColors.emergencyRed,
                background: const Color(0xFFFEF2F2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DocStatTile(
                icon: Icons.sell_outlined,
                value: '$categories',
                label: 'Kategorien',
                color: const Color(0xFF16A34A),
                background: const Color(0xFFF0FDF4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DocStatTile extends StatelessWidget {
  const _DocStatTile({
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
      height: 120,
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
          const SizedBox(height: 4),
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
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFEF2F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFFCA5A5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: GpColors.emergencyRed),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count Dokument${count == 1 ? '' : 'e'} erfordert Aufmerksamkeit',
                style: const TextStyle(
                  color: GpColors.emergencyRed,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentFilterCard extends StatelessWidget {
  const _DocumentFilterCard({
    required this.controller,
    required this.query,
    required this.categories,
    required this.selectedCategory,
    required this.selectedUrgency,
    required this.resultCount,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onUrgencyChanged,
  });

  final TextEditingController controller;
  final String query;
  final List<String> categories;
  final String selectedCategory;
  final String selectedUrgency;
  final int resultCount;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onUrgencyChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              key: const ValueKey('document-search'),
              controller: controller,
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Dokumente durchsuchen...',
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Suche löschen',
                        onPressed: () {
                          controller.clear();
                          onQueryChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Typ',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) onCategoryChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedUrgency,
                    decoration: const InputDecoration(
                      labelText: 'Dringlichkeit',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Alle', child: Text('Alle')),
                      DropdownMenuItem(
                        value: 'Dringend',
                        child: Text('Dringend'),
                      ),
                      DropdownMenuItem(value: 'Hoch', child: Text('Hoch')),
                      DropdownMenuItem(value: 'Mittel', child: Text('Mittel')),
                      DropdownMenuItem(
                        value: 'Niedrig',
                        child: Text('Niedrig'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onUrgencyChanged(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$resultCount Dokument${resultCount == 1 ? '' : 'e'} lokal gefunden',
                style: const TextStyle(
                  color: GpColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.repo,
    required this.entry,
    required this.onDelete,
  });

  final DocumentRepository repo;
  final _DocumentEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final doc = entry.document;
    final urgencyColor = _urgencyColor(entry.insights.urgency);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: _DocumentThumb(repo: repo, document: doc),
        title: Text(
          doc.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _DocBadge(
                label: doc.category,
                color: const Color(0xFF2563EB),
                background: const Color(0xFFEFF6FF),
              ),
              _DocBadge(
                label: _date(doc.capturedAt),
                color: GpColors.textSecondary,
                background: const Color(0xFFF3F4F6),
              ),
              _DocBadge(
                label: entry.insights.urgency.label,
                color: urgencyColor,
                background: urgencyColor.withValues(alpha: 0.12),
              ),
              if (doc.encrypted)
                const _DocBadge(
                  label: 'Verschlüsselt',
                  color: Color(0xFF16A34A),
                  background: Color(0xFFF0FDF4),
                ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: 'Loeschen',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          if ((doc.notes ?? '').trim().isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                doc.notes!.trim(),
                style: const TextStyle(color: GpColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
          ],
          MedicalInsightsCard(insights: entry.insights),
        ],
      ),
    );
  }
}

class _DocBadge extends StatelessWidget {
  const _DocBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
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

Color _urgencyColor(InsightUrgency urgency) {
  return switch (urgency) {
    InsightUrgency.low => const Color(0xFF2563EB),
    InsightUrgency.medium => const Color(0xFFCA8A04),
    InsightUrgency.high => const Color(0xFFEA580C),
    InsightUrgency.urgent => GpColors.emergencyRed,
  };
}

String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';
