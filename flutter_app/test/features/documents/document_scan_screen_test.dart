import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/documents/presentation/document_scan_screen.dart';
import 'package:image_picker/image_picker.dart';

void main() {
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

    await tester.tap(find.text('Galerie'));
    await tester.pumpAndSettle();

    expect(pickedSource, ImageSource.gallery);
    expect(find.textContaining('Galerie-Zugriff ist blockiert'), findsNothing);
  });
}
