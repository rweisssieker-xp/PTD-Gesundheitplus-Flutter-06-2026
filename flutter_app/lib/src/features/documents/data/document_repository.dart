import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/health_document.dart';

class DocumentRepository {
  DocumentRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<HealthDocument> addDocument({
    required String title,
    required String category,
    required String sourcePath,
    required String documentsDir,
    String? mimeType,
    DateTime? capturedAt,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final source = File(sourcePath);
    final extension = p.extension(sourcePath);
    final targetDir = Directory(p.join(documentsDir, 'health_documents'));
    if (!targetDir.existsSync()) targetDir.createSync(recursive: true);
    final targetPath = p.join(targetDir.path, '$id$extension');
    if (source.existsSync()) {
      await source.copy(targetPath);
    } else {
      File(targetPath).writeAsStringSync('');
    }
    final now = DateTime.now().toIso8601String();
    final captured = capturedAt ?? DateTime.now();
    _db.execute(
      '''
      INSERT INTO health_documents (
        id, title, category, local_path, mime_type, captured_at, notes, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        title,
        category,
        targetPath,
        mimeType,
        captured.toIso8601String(),
        notes,
        now,
        now,
      ],
    );
    return HealthDocument(
      id: id,
      title: title,
      category: category,
      localPath: targetPath,
      mimeType: mimeType,
      capturedAt: captured,
      notes: notes,
    );
  }

  Future<List<HealthDocument>> listDocuments() async {
    final rows = _db.select('''
      SELECT id, title, category, local_path, mime_type, captured_at, notes
      FROM health_documents
      ORDER BY captured_at DESC
      ''');
    return rows
        .map(
          (row) => HealthDocument(
            id: row['id'] as String,
            title: row['title'] as String,
            category: row['category'] as String,
            localPath: row['local_path'] as String,
            mimeType: row['mime_type'] as String?,
            capturedAt: DateTime.parse(row['captured_at'] as String),
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<void> deleteDocument(String id) async {
    final rows = _db.select(
      'SELECT local_path FROM health_documents WHERE id = ? LIMIT 1',
      [id],
    );
    if (rows.isNotEmpty) {
      final file = File(rows.first['local_path'] as String);
      if (file.existsSync()) file.deleteSync();
    }
    _db.execute('DELETE FROM health_documents WHERE id = ?', [id]);
  }

  Future<File> exportHealthRecord(String exportDir) async {
    final dir = Directory(exportDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File(
      p.join(
        dir.path,
        'gesundheit_plus_export_${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );
    final payload = <String, Object?>{};
    for (final table in _db.allTables) {
      final rows = _db.select('SELECT * FROM ${table.actualTableName}');
      payload[table.actualTableName] = rows
          .map((row) => Map<String, Object?>.from(row))
          .toList();
    }
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'source': 'Gesundheit Plus',
        'createdAt': DateTime.now().toIso8601String(),
        'storageMode': 'local-device',
        'data': payload,
      }),
    );
    return file;
  }
}
