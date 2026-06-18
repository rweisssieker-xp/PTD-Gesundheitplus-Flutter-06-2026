import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/privacy/data/storage_mode_repository.dart';
import 'package:gesundheitplus/src/features/privacy/presentation/storage_mode_screen.dart';

void main() {
  testWidgets('storage mode screen shows local-first PWA parity controls', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await StorageModeRepository(db).selectLocalMode();
    _seedStorageData(db);

    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: StorageModeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Speicher-Modus'), findsWidgets);
    expect(find.text('Lokaler Modus aktiv'), findsOneWidget);
    expect(find.text('Lokal'), findsWidgets);
    expect(find.text('Modus wechseln'), findsOneWidget);
    expect(
      find.textContaining('Cloud-Sync ist absichtlich deaktiviert'),
      findsOneWidget,
    );
    expect(find.text('Lokale Datenverwaltung'), findsOneWidget);
    expect(find.text('Backup als JSON erstellen'), findsOneWidget);
    expect(find.text('Alle lokalen Daten löschen'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Unterschiede der Modi'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Unterschiede der Modi'), findsOneWidget);
    expect(find.textContaining('Maximaler Datenschutz'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Lokaler Speicherinhalt'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Gesundheitsdaten'), findsOneWidget);
    expect(find.text('Dokumente'), findsOneWidget);
    expect(find.text('Notfall & Kommunikation'), findsOneWidget);
  });
}

void _seedStorageData(AppDatabase db) {
  db.execute('''
    INSERT INTO medications (
      id, name, active, reminder_times_json, created_at, updated_at
    )
    VALUES ('med-1', 'ASS', 1, '[]', 'now', 'now')
    ''');
  db.execute('''
    INSERT INTO health_documents (
      id, title, category, local_path, captured_at, created_at, updated_at
    )
    VALUES ('doc-1', 'Labor', 'Labor', '/tmp/labor.pdf', 'now', 'now', 'now')
    ''');
  db.execute('''
    INSERT INTO emergency_contacts (
      id, name, phone, verified, created_at, updated_at
    )
    VALUES ('contact-1', 'Anna', '+491234', 1, 'now', 'now')
    ''');
}
