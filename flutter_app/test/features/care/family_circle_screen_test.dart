import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/care/data/care_repository.dart';
import 'package:gesundheitplus/src/features/care/presentation/family_circle_screen.dart';

void main() {
  testWidgets('family circle shows PWA-style local safety status overview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = CareRepository(db);
    await repo.addFamilyMember(
      name: 'Anna',
      relationship: 'Tochter',
      phone: '+49123',
    );
    final anna = (await repo.listFamilyMembers()).single;
    await repo.addFamilyMember(name: 'Bernd', relationship: 'Bruder');
    await repo.addCheckIn(
      memberId: anna.id,
      memberName: anna.name,
      status: 'help_needed',
      note: 'Bitte anrufen',
      locationText: '52.5200, 13.4050',
      checkedAt: DateTime.now().subtract(const Duration(days: 2)),
      nextCheckInDue: DateTime.now().subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: FamilyCircleScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Familien-Sicherheitskreis'), findsOneWidget);
    expect(
      find.text('Status-Updates und Bin-sicher-Check-ins lokal verwalten'),
      findsOneWidget,
    );
    expect(find.text('Hilfe'), findsOneWidget);
    expect(find.text('Unbekannt'), findsOneWidget);
    expect(find.text('Mein Status senden'), findsOneWidget);
    expect(find.text('Familienmitglieder'), findsOneWidget);
    expect(find.text('Anna'), findsWidgets);
    expect(find.text('Bernd'), findsOneWidget);
    expect(find.text('Überfällig'), findsWidgets);
    expect(find.text('So funktioniert der Sicherheitskreis'), findsOneWidget);
    expect(find.textContaining('Brauche-Hilfe-Check-ins'), findsOneWidget);
  });
}
