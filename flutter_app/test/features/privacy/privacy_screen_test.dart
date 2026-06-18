import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/privacy/presentation/privacy_screen.dart';

void main() {
  testWidgets('privacy screen keeps GDPR sections from original PWA', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    _seedPrivacyData(db);

    tester.view.physicalSize = const Size(430, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: PrivacyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Datenschutz & Sicherheit'), findsOneWidget);
    expect(find.text('Daten exportieren'), findsWidgets);
    expect(find.text('Daten löschen'), findsOneWidget);
    expect(find.text('Ihre Datensicherheit'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Welche Daten speichern wir?'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Welche Daten speichern wir?'), findsOneWidget);
    expect(find.text('Gesundheitsdaten'), findsOneWidget);
    expect(find.text('2 lokal'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ihre Rechte (DSGVO)'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Auskunftsrecht (Art. 15)'), findsOneWidget);
    expect(find.text('Datenübertragbarkeit (Art. 20)'), findsOneWidget);
    expect(find.text('Löschungsrecht (Art. 17)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Zweck der Datenverarbeitung'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Zweck der Datenverarbeitung'), findsOneWidget);
    expect(find.text('Fragen zum Datenschutz?'), findsOneWidget);
  });
}

void _seedPrivacyData(AppDatabase db) {
  db.execute('''
    INSERT INTO medications (
      id, name, active, reminder_times_json, created_at, updated_at
    )
    VALUES ('med-1', 'ASS', 1, '[]', 'now', 'now')
    ''');
  db.execute('''
    INSERT INTO allergies (
      id, substance, category, severity, created_at, updated_at
    )
    VALUES ('allergy-1', 'Penicillin', 'Medikament', 'Schwer', 'now', 'now')
    ''');
}
