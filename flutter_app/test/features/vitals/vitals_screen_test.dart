import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/vitals/data/vitals_repository.dart';
import 'package:gesundheitplus/src/features/vitals/presentation/blood_pressure_screen.dart';
import 'package:gesundheitplus/src/features/vitals/presentation/weight_screen.dart';

void main() {
  testWidgets('blood pressure screen mirrors PWA stats and trend workflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = VitalsRepository(db);
    final now = DateTime.now();
    await repo.addBloodPressure(
      systolic: 118,
      diastolic: 78,
      pulse: 68,
      context: 'Morgens',
      measuredAt: now.subtract(const Duration(days: 3)),
    );
    await repo.addBloodPressure(
      systolic: 132,
      diastolic: 86,
      pulse: 72,
      context: 'Abends',
      measuredAt: now.subtract(const Duration(days: 2)),
    );
    await repo.addBloodPressure(
      systolic: 146,
      diastolic: 92,
      pulse: 76,
      context: 'Bei Unwohlsein',
      measuredAt: now.subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: BloodPressureScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blutdruck'), findsOneWidget);
    expect(find.text('Letzte Messung'), findsOneWidget);
    expect(find.text('146/92'), findsWidgets);
    expect(find.text('Ø Systole'), findsOneWidget);
    expect(find.text('Ø Diastole'), findsOneWidget);
    expect(find.text('Max'), findsOneWidget);
    expect(find.text('Min'), findsOneWidget);
    expect(find.text('Trend: Steigend'), findsOneWidget);
    expect(find.text('Verlauf'), findsWidgets);
    expect(find.text('Historie'), findsOneWidget);
    expect(find.text('Hoch >130'), findsOneWidget);
  });

  testWidgets('blood pressure screen saves a new local measurement flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: BloodPressureScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Blutdruckwerte'), findsOneWidget);

    await tester.tap(find.text('Messung'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Systole (mmHg) *'),
      '142',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Diastole (mmHg) *'),
      '91',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Puls (bpm)'), '73');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('142/91'), findsWidgets);
    expect(find.text('73'), findsWidgets);

    final logs = await VitalsRepository(db).listBloodPressure();
    expect(logs, hasLength(1));
    expect(logs.single.systolic, 142);
    expect(logs.single.diastolic, 91);
    expect(logs.single.pulse, 73);
    expect(logs.single.context, 'Ruhe');
  });

  testWidgets('weight screen shows PWA dashboard cards and local BMI history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = VitalsRepository(db);
    final now = DateTime.now();
    await repo.addWeight(
      weightKg: 82,
      heightCm: 180,
      measuredAt: now.subtract(const Duration(days: 8)),
    );
    await repo.addWeight(
      weightKg: 80,
      heightCm: 180,
      measuredAt: now.subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: WeightScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gewicht & BMI'), findsOneWidget);
    expect(find.text('Aktuelles Gewicht'), findsOneWidget);
    expect(find.text('Ihr BMI'), findsOneWidget);
    expect(find.text('Normalgewicht'), findsOneWidget);
    expect(find.text('Verlauf'), findsOneWidget);
    expect(find.text('Historie'), findsOneWidget);
    expect(find.text('80.0 kg'), findsWidgets);
    expect(find.textContaining('BMI 24.7'), findsWidgets);
  });

  testWidgets('weight screen saves a new local weight and BMI flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: WeightScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Gewichtswerte'), findsWidgets);

    await tester.tap(find.text('Messung'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Gewicht (kg) *'),
      '79,5',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Groesse cm'), '180');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('79.5 kg'), findsWidgets);
    expect(find.text('24.5'), findsOneWidget);
    expect(find.textContaining('BMI 24.5'), findsWidgets);

    final logs = await VitalsRepository(db).listWeight();
    expect(logs, hasLength(1));
    expect(logs.single.weightKg, 79.5);
    expect(logs.single.heightCm, 180);
    expect(logs.single.bmi, closeTo(24.5, 0.05));
  });
}
