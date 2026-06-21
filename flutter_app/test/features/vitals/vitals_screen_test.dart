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
}
