import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/health_record/data/health_record_repository.dart';
import 'package:gesundheitplus/src/features/health_record/presentation/treatment_history_screen.dart';

void main() {
  testWidgets('treatment history creates lists and deletes local records', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: TreatmentHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Behandlungen'), findsOneWidget);
    expect(find.text('0 Eintraege'), findsOneWidget);
    expect(find.text('Sprachführung'), findsOneWidget);
    expect(find.text('Vorlesen'), findsOneWidget);
    expect(find.text('Noch keine Behandlungen'), findsOneWidget);

    await tester.tap(find.text('Behandlung'));
    await tester.pumpAndSettle();

    expect(find.text('Behandlung erfassen'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Titel *'),
      'Physiotherapie',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Arzt / Praxis'),
      'Praxis Meyer',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Fachrichtung'),
      'Orthopaedie',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Ergebnis'),
      'Beweglichkeit verbessert',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('1 Eintraege'), findsOneWidget);
    expect(find.text('Physiotherapie'), findsOneWidget);
    expect(find.textContaining('Praxis Meyer'), findsOneWidget);
    expect(find.textContaining('Beweglichkeit verbessert'), findsOneWidget);

    final created = await HealthRecordRepository(db).listTreatments();
    expect(created.single.title, 'Physiotherapie');
    expect(created.single.provider, 'Praxis Meyer');
    expect(created.single.specialty, 'Orthopaedie');
    expect(created.single.outcome, 'Beweglichkeit verbessert');

    await tester.tap(find.byTooltip('Loeschen'));
    await tester.pumpAndSettle();

    expect(find.text('0 Eintraege'), findsOneWidget);
    expect(find.text('Noch keine Behandlungen'), findsOneWidget);
    expect(await HealthRecordRepository(db).listTreatments(), isEmpty);
  });
}
