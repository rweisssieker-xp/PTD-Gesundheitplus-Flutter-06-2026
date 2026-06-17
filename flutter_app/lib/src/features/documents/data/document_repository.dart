import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/health_document.dart';

class DocumentRepository {
  DocumentRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;
  static final _fileCipher = AesGcm.with256bits();

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
    final targetPath = p.join(targetDir.path, '$id$extension.gpf');
    final sourceBytes = source.existsSync()
        ? await source.readAsBytes()
        : <int>[];
    final secretKey = await _fileCipher.newSecretKey();
    final secretKeyBytes = await secretKey.extractBytes();
    final secretBox = await _fileCipher.encrypt(
      sourceBytes,
      secretKey: secretKey,
    );
    await File(targetPath).writeAsBytes(secretBox.cipherText);
    final now = DateTime.now().toIso8601String();
    final captured = capturedAt ?? DateTime.now();
    _db.execute(
      '''
      INSERT INTO health_documents (
        id, title, category, local_path, mime_type, file_key, file_nonce,
        file_mac, encrypted, captured_at, notes, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?)
      ''',
      [
        id,
        title,
        category,
        targetPath,
        mimeType,
        base64Encode(secretKeyBytes),
        base64Encode(secretBox.nonce),
        base64Encode(secretBox.mac.bytes),
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
      fileKey: base64Encode(secretKeyBytes),
      fileNonce: base64Encode(secretBox.nonce),
      fileMac: base64Encode(secretBox.mac.bytes),
      encrypted: true,
      capturedAt: captured,
      notes: notes,
    );
  }

  Future<List<HealthDocument>> listDocuments() async {
    final rows = _db.select('''
      SELECT id, title, category, local_path, mime_type, file_key, file_nonce,
             file_mac, encrypted, captured_at, notes
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
            fileKey: row['file_key'] as String?,
            fileNonce: row['file_nonce'] as String?,
            fileMac: row['file_mac'] as String?,
            encrypted: row['encrypted'] == 1,
            capturedAt: DateTime.parse(row['captured_at'] as String),
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<List<int>> readDocumentBytes(HealthDocument document) async {
    final file = File(document.localPath);
    if (!file.existsSync()) return const [];
    final bytes = await file.readAsBytes();
    if (!document.encrypted) return bytes;

    final key = document.fileKey;
    final nonce = document.fileNonce;
    final mac = document.fileMac;
    if (key == null || nonce == null || mac == null) {
      throw StateError('Encrypted document metadata is incomplete.');
    }

    final secretBox = SecretBox(
      bytes,
      nonce: base64Decode(nonce),
      mac: Mac(base64Decode(mac)),
    );
    return _fileCipher.decrypt(
      secretBox,
      secretKey: SecretKey(base64Decode(key)),
    );
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
