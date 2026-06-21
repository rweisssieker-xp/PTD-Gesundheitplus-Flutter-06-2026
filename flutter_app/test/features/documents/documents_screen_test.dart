import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/documents/presentation/documents_screen.dart';

void main() {
  testWidgets(
    'documents screen shows local search filters and attention state',
    (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      _seedDocuments(db);

      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
          child: const MaterialApp(home: DocumentsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gescannte Dokumente'), findsOneWidget);
      expect(
        find.text('Lokal gespeicherte Gesundheitsdokumente'),
        findsOneWidget,
      );
      expect(find.text('2'), findsWidgets);
      expect(find.text('1 Dokument erfordert Aufmerksamkeit'), findsOneWidget);
      expect(find.text('2 Dokumente lokal gefunden'), findsOneWidget);
      expect(find.text('Labor kritisch'), findsOneWidget);
      expect(find.text('Impfpass Kontrolle'), findsOneWidget);
      expect(find.text('Dringend'), findsWidgets);
      expect(find.text('Verschlüsselt'), findsWidgets);

      await tester.enterText(
        find.byKey(const ValueKey('document-search')),
        'impf',
      );
      await tester.pumpAndSettle();

      expect(find.text('1 Dokument lokal gefunden'), findsOneWidget);
      expect(find.text('Impfpass Kontrolle'), findsOneWidget);
      expect(find.text('Labor kritisch'), findsNothing);

      await tester.enterText(find.byKey(const ValueKey('document-search')), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alle').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dringend').last);
      await tester.pumpAndSettle();

      expect(find.text('1 Dokument lokal gefunden'), findsOneWidget);
      expect(find.text('Labor kritisch'), findsOneWidget);
      expect(find.text('Impfpass Kontrolle'), findsNothing);
    },
  );
}

void _seedDocuments(AppDatabase db) {
  db.execute('''
    INSERT INTO health_documents (
      id, title, category, local_path, encrypted, captured_at, notes,
      created_at, updated_at
    )
    VALUES (
      'doc-1',
      'Labor kritisch',
      'Laborbefund',
      '/tmp/labor.pdf',
      1,
      '2026-06-01T00:00:00.000',
      'CRP kritisch dringend kontrollieren',
      'now',
      'now'
    )
    ''');
  db.execute('''
    INSERT INTO health_documents (
      id, title, category, local_path, encrypted, captured_at, notes,
      created_at, updated_at
    )
    VALUES (
      'doc-2',
      'Impfpass Kontrolle',
      'Impfpass',
      '/tmp/impfpass.pdf',
      1,
      '2026-06-02T00:00:00.000',
      'Booster dokumentiert',
      'now',
      'now'
    )
    ''');
}
