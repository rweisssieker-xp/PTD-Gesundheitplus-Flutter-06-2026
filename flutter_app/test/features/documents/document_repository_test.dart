import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/documents/data/document_repository.dart';

void main() {
  test('stores documents encrypted locally and deletes copied file', () async {
    final db = AppDatabase.memory();
    final temp = await Directory.systemTemp.createTemp('gp_docs_test');
    final source = File('${temp.path}/source.txt')..writeAsStringSync('scan');
    final repo = DocumentRepository(db);
    final doc = await repo.addDocument(
      title: 'Labor',
      category: 'Befund',
      sourcePath: source.path,
      documentsDir: temp.path,
      mimeType: 'text/plain',
      capturedAt: DateTime(2026, 6, 17),
    );
    expect(File(doc.localPath).existsSync(), isTrue);
    expect(File(doc.localPath).readAsBytesSync(), isNot(utf8.encode('scan')));
    expect(doc.localPath, endsWith('.gpf'));
    expect(doc.encrypted, isTrue);

    final stored = (await repo.listDocuments()).single;
    expect(stored.title, 'Labor');
    expect(stored.encrypted, isTrue);
    expect(await repo.readDocumentBytes(stored), utf8.encode('scan'));
    await repo.deleteDocument(doc.id);
    expect(File(doc.localPath).existsSync(), isFalse);
    expect(await repo.listDocuments(), isEmpty);
    db.close();
    temp.deleteSync(recursive: true);
  });

  test('exports local health record as json', () async {
    final db = AppDatabase.memory();
    final temp = await Directory.systemTemp.createTemp('gp_export_test');
    db.execute('''
      INSERT INTO notifications (id, title, body, category, read, created_at)
      VALUES ('n1', 'Test', 'Body', 'system', 0, '2026-06-17T00:00:00')
      ''');
    db.execute('''
      INSERT INTO health_passes (
        id, pass_type, title, manufacturer, serial_number, created_at, updated_at
      )
      VALUES ('pass-1', 'Implantatpass', 'Knieprothese', 'MediCorp', 'SN123', 'now', 'now')
      ''');
    final file = await DocumentRepository(db).exportHealthRecord(temp.path);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(json['storageMode'], 'local-device');
    expect(json['data']['notifications'], isNotEmpty);
    expect(json['data']['health_passes'], isNotEmpty);
    expect(json['data']['health_passes'].single['title'], 'Knieprothese');
    db.close();
    temp.deleteSync(recursive: true);
  });
}
