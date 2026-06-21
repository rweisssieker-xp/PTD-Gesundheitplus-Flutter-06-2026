import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/documents/presentation/export_screen.dart';

void main() {
  testWidgets('creates and shares local health record json export', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    db.execute('''
      INSERT INTO medications (
        id, name, dosage, frequency, active, reminder_times_json, created_at, updated_at
      )
      VALUES ('med-1', 'Ramipril', '5mg', '1x taeglich', 1, '["08:00"]', 'now', 'now')
    ''');

    final tempDir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('gp-export-success-test-'),
    ))!;
    addTearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException {
          // Windows can keep the just-read export file locked briefly.
        }
      }
    });
    File? sharedFile;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: MaterialApp(
          home: ExportScreen(
            directoryProvider: () async => tempDir,
            exporter: (directory) async {
              final file = File(
                '$directory${Platform.pathSeparator}gesundheit_plus_export.json',
              );
              final rows = db.select('SELECT * FROM medications');
              file.writeAsStringSync(
                const JsonEncoder.withIndent('  ').convert({
                  'source': 'Gesundheit Plus',
                  'storageMode': 'local-device',
                  'data': {
                    'medications': rows
                        .map((row) => Map<String, Object?>.from(row))
                        .toList(),
                  },
                }),
              );
              return file;
            },
            shareFile: (file) async => sharedFile = file,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final createButtonFinder = find.byKey(
      const Key('health-export-create-button'),
    );
    await tester.ensureVisible(createButtonFinder);
    expect(
      tester.widget<FilledButton>(createButtonFinder).onPressed,
      isNotNull,
    );
    await tester.tap(createButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Export bereit'), findsOneWidget);
    final files = tempDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
    expect(files, hasLength(1));

    final payload =
        jsonDecode(files.single.readAsStringSync()) as Map<String, dynamic>;
    expect(payload['source'], 'Gesundheit Plus');
    expect(payload['storageMode'], 'local-device');
    final data = payload['data'] as Map<String, dynamic>;
    final medications = data['medications'] as List<dynamic>;
    expect(medications.single, containsPair('name', 'Ramipril'));
    expect(medications.single, containsPair('dosage', '5mg'));

    await tester.tap(find.byKey(const Key('health-export-share-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(sharedFile?.path, files.single.path);
  });

  testWidgets('shows recovery message when health record export fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    final tempDir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('gp-export-test-'),
    ))!;
    addTearDown(() => tempDir.deleteSync(recursive: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: MaterialApp(
          home: ExportScreen(
            directoryProvider: () async => tempDir,
            exporter: (_) async => throw const FileSystemException('full disk'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Exportdatei erstellen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Export konnte nicht erstellt werden'),
      findsOneWidget,
    );
  });

  testWidgets('shows recovery message when health record sharing fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    final tempDir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('gp-share-test-'),
    ))!;
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final exportFile = File(
      '${tempDir.path}${Platform.pathSeparator}data.json',
    );
    await tester.runAsync(() => exportFile.writeAsString('{}'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: MaterialApp(
          home: ExportScreen(
            directoryProvider: () async => tempDir,
            exporter: (_) async => exportFile,
            shareFile: (_) async => throw StateError('share unavailable'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Exportdatei erstellen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Export bereit'), findsOneWidget);

    await tester.tap(find.text('Teilen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Export konnte nicht geteilt werden.'), findsOneWidget);
  });
}
