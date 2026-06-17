import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/health_record/presentation/anamnesis_screen.dart';

void main() {
  testWidgets('anamnesis screen keeps original PWA page layout', (
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
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: AnamnesisScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Krankengeschichte'), findsOneWidget);
    expect(find.text('Ihre medizinische Anamnese'), findsOneWidget);
    expect(find.text('Bearbeiten'), findsOneWidget);
    expect(find.text('Sprachführung'), findsOneWidget);
    expect(find.text('Vorlesen'), findsOneWidget);
    expect(find.text('QR-Code für Weitergabe'), findsOneWidget);
    expect(find.text('QR-Code generieren'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
