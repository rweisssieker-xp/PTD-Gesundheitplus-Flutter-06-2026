import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/documents/presentation/document_scan_screen.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  testWidgets('shows local PWA-style document type workflow', (tester) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: MaterialApp(
          home: DocumentScanScreen(
            permissionGate: (_) async => true,
            imagePicker: (_) async => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dokument scannen'), findsOneWidget);
    expect(
      find.text('Gesundheitsdokumente lokal aufnehmen und analysieren'),
      findsOneWidget,
    );
    expect(find.text('Was möchten Sie scannen?'), findsOneWidget);
    expect(find.text('Arztbrief'), findsWidgets);
    expect(find.text('Rezept'), findsOneWidget);
    expect(find.text('Laborbefund'), findsOneWidget);
    expect(find.text('Sie scannen: Arztbrief'), findsOneWidget);
    expect(find.text('Lokal'), findsWidgets);

    await tester.tap(find.text('Laborbefund'));
    await tester.pumpAndSettle();

    expect(find.text('Sie scannen: Laborbefund'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.controller?.text == 'Neuer Laborbefund',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Erweiterte Angaben'));
    await tester.pumpAndSettle();

    expect(find.text('Dokumentdatum'), findsOneWidget);
    expect(find.text('Behandelnde Praxis / Arzt'), findsOneWidget);
    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('Lokale Aufnahme'), findsOneWidget);
    expect(
      find.textContaining('Die Analyse ist regelbasiert lokal'),
      findsOneWidget,
    );
  });

  testWidgets('shows camera permission recovery instead of opening picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    var pickerCalled = false;
    var settingsOpened = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: MaterialApp(
          home: DocumentScanScreen(
            permissionGate: (_) async => false,
            imagePicker: (_) async {
              pickerCalled = true;
              return null;
            },
            openSettings: () async {
              settingsOpened = true;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Kamera'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Kamera'));
    await tester.pumpAndSettle();

    expect(pickerCalled, isFalse);
    expect(find.textContaining('Kamera-Zugriff ist blockiert'), findsOneWidget);
    expect(find.text('Systemeinstellungen öffnen'), findsOneWidget);

    await tester.tap(find.text('Systemeinstellungen öffnen'));
    await tester.pumpAndSettle();

    expect(settingsOpened, isTrue);
  });

  testWidgets('opens gallery picker after permission is granted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    ImageSource? pickedSource;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: MaterialApp(
          home: DocumentScanScreen(
            permissionGate: (_) async => true,
            imagePicker: (source) async {
              pickedSource = source;
              return null;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Galerie'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Galerie'));
    await tester.pumpAndSettle();

    expect(pickedSource, ImageSource.gallery);
    expect(find.textContaining('Galerie-Zugriff ist blockiert'), findsNothing);
  });

  testWidgets(
    'saves selected gallery document through local storage contract',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.memory();
      final temp = Directory.systemTemp.createTempSync('gp_doc_scan_widget');
      addTearDown(db.close);
      addTearDown(() {
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      });

      final source = File('${temp.path}${Platform.pathSeparator}labor.txt')
        ..writeAsStringSync('HbA1c 7.1');
      final saved = <String, Object?>{};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) => db)],
          child: MaterialApp(
            home: DocumentScanScreen(
              permissionGate: (_) async => true,
              imagePicker: (_) async =>
                  XFile(source.path, name: 'labor.txt', mimeType: 'text/plain'),
              storageDirectoryProvider: () =>
                  SynchronousFuture<Directory>(temp),
              documentSaver:
                  ({
                    required db,
                    required title,
                    required category,
                    required sourcePath,
                    required documentsDir,
                    mimeType,
                    capturedAt,
                    notes,
                  }) {
                    saved.addAll({
                      'db': db,
                      'title': title,
                      'category': category,
                      'sourcePath': sourcePath,
                      'documentsDir': documentsDir,
                      'mimeType': mimeType,
                      'capturedAt': capturedAt,
                      'notes': notes,
                    });
                    return SynchronousFuture<void>(null);
                  },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Laborbefund'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Titel *'),
        'Labor Juni',
      );
      await tester.scrollUntilVisible(
        find.text('Galerie'),
        360,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Galerie'));
      await tester.pumpAndSettle();

      expect(find.text('labor.txt'), findsOneWidget);
      expect(find.text('Bereit zum lokalen Speichern'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Dokument lokal speichern'),
        360,
        scrollable: find.byType(Scrollable).first,
      );
      final saveButton = find.ancestor(
        of: find.text('Dokument lokal speichern'),
        matching: find.bySubtype<ButtonStyleButton>(),
      );
      final save = tester.widget<ButtonStyleButton>(saveButton).onPressed;
      expect(save, isNotNull);
      save!();
      await tester.pump();

      expect(find.text('Dokument lokal gespeichert'), findsOneWidget);
      expect(saved['db'], same(db));
      expect(saved['title'], 'Labor Juni');
      expect(saved['category'], 'Laborbefund');
      expect(saved['sourcePath'], source.path);
      expect(saved['documentsDir'], temp.path);
      expect(saved['mimeType'], 'text/plain');
      expect(saved['capturedAt'], isNull);
      expect(saved['notes'], isNull);
    },
  );
}
