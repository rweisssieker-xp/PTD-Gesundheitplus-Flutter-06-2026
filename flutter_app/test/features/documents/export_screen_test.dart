import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/documents/presentation/export_screen.dart';

void main() {
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
