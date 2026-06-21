import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/health_record/data/health_record_repository.dart';
import 'package:gesundheitplus/src/features/health_record/presentation/allergies_screen.dart';

void main() {
  testWidgets(
    'allergies screen creates edits warns and deletes local allergy',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.memory();
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) => db)],
          child: const MaterialApp(home: AllergiesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bekannte Allergien'), findsOneWidget);
      expect(find.text('Sprachführung'), findsOneWidget);
      expect(find.text('Allergie & Medikamenten-Check'), findsOneWidget);
      expect(find.text('Noch keine Allergien eingetragen'), findsOneWidget);

      await tester.tap(find.text('Erste Allergie hinzufügen'));
      await tester.pumpAndSettle();

      expect(find.text('Neue Allergie'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Allergen / Unverträglichkeit *'),
        'Penicillin',
      );
      await tester.tap(find.text('Mittel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Schwer').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Reaktion'),
        'Atemnot',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Festgestellt von'),
        'Hausarzt',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Notizen'),
        'Notfallpass vorhanden',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Penicillin'), findsWidgets);
      expect(find.text('Medikament (1)'), findsOneWidget);
      expect(find.text('WICHTIG: Schwere Allergien'), findsOneWidget);
      expect(find.text('Atemnot'), findsOneWidget);
      expect(find.textContaining('Hausarzt'), findsOneWidget);
      expect(find.text('Notfallpass vorhanden'), findsOneWidget);

      var allergies = await HealthRecordRepository(db).listAllergies();
      expect(allergies.single.substance, 'Penicillin');
      expect(allergies.single.severity, 'Schwer');
      expect(allergies.single.reaction, 'Atemnot');

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bearbeiten'));
      await tester.pumpAndSettle();

      expect(find.text('Allergie bearbeiten'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Allergen / Unverträglichkeit *'),
        'Penicillin V',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();

      allergies = await HealthRecordRepository(db).listAllergies();
      expect(allergies.single.substance, 'Penicillin V');
      expect(find.text('Penicillin V'), findsWidgets);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();

      expect(await HealthRecordRepository(db).listAllergies(), isEmpty);
      expect(find.text('Noch keine Allergien eingetragen'), findsOneWidget);
    },
  );
}
