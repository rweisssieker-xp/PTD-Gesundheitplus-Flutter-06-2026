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

    await tester.scrollUntilVisible(
      find.text('Device-only Modus'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Alles lokal auf dem Gerät'), findsOneWidget);
    expect(find.text('Keine Cloud-Synchronisation'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Exportumfang'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Der JSON-Export enthält:'), findsOneWidget);
    expect(
      find.textContaining('Profil- und App-Einstellungen'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Dokument-Metadaten ohne externe Cloud-Kopie'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Löschumfang'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Betroffen sind alle lokalen Gesundheitsdaten'),
      findsOneWidget,
    );
    expect(
      find.text('Nicht betroffen ist die App-Installation'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Fragen zum Datenschutz?'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Fragen zum Datenschutz?'), findsOneWidget);
  });

  testWidgets('privacy delete dialog explains affected local data', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    _seedPrivacyData(db);

    tester.view.physicalSize = const Size(430, 1200);
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

    await tester.tap(find.text('Daten löschen'));
    await tester.pumpAndSettle();

    expect(find.text('Alle lokalen Daten löschen?'), findsOneWidget);
    expect(find.text('WARNUNG: Unwiderrufliche Löschung'), findsOneWidget);
    expect(find.text('Betroffen sind:'), findsOneWidget);
    expect(
      find.text(
        'Nicht betroffen: App-Installation und Betriebssystem-Berechtigungen bleiben bestehen. Sie können die App danach weiter lokal nutzen.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('KI-Analysen, Coach-Nachrichten und Empfehlungen'),
      findsOneWidget,
    );
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
