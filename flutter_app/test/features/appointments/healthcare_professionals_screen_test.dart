import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/appointments/data/appointment_repository.dart';
import 'package:gesundheitplus/src/features/appointments/domain/healthcare_professional.dart';
import 'package:gesundheitplus/src/features/appointments/presentation/healthcare_professionals_screen.dart';

void main() {
  testWidgets('healthcare professionals screen shows PWA parity directory', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = AppointmentRepository(db);
    await repo.saveProfessional(
      const HealthcareProfessional(
        id: 'prof-1',
        name: 'Dr. Anna Herz',
        specialty: 'Kardiologie',
        address: 'Herzweg 1, Berlin',
        phone: '+4930123456',
        email: 'anna.herz@example.test',
        notes: 'Sportmedizin',
        treatingSince: null,
      ),
    );
    await repo.saveProfessional(
      HealthcareProfessional(
        id: 'prof-2',
        name: 'Praxis Hautklar',
        specialty: 'Dermatologie',
        address: 'Hautstrasse 2, Berlin',
        phone: null,
        email: null,
        notes: 'Hautscreening',
        treatingSince: DateTime(2024, 5, 20),
      ),
    );

    tester.view.physicalSize = const Size(430, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: HealthcareProfessionalsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heilberufe'), findsWidgets);
    expect(find.text('Ihre Aerzte und Behandler'), findsOneWidget);
    expect(find.text('2 Behandler gespeichert'), findsOneWidget);
    expect(find.text('Fachrichtungen'), findsOneWidget);
    expect(find.text('Kontaktbereit'), findsOneWidget);
    expect(find.text('Meine Behandler durchsuchen'), findsOneWidget);
    expect(find.text('Kardiologie'), findsWidgets);
    expect(find.text('Dermatologie'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Praxis Hautklar'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('In Behandlung seit 20.5.2024'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Dr. Anna Herz'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dr. Anna Herz'), findsOneWidget);
    expect(find.text('Anrufen'), findsOneWidget);
    expect(find.text('E-Mail'), findsOneWidget);
    expect(find.text('Karte'), findsWidgets);

    final searchField = find.byKey(
      const ValueKey('professional-list-search'),
      skipOffstage: false,
    );
    await tester.scrollUntilVisible(
      searchField,
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('professional-list-search')),
      'dermatologie',
    );
    await tester.pumpAndSettle();

    expect(find.text('1 Treffer lokal gefunden'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Praxis Hautklar'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Praxis Hautklar'), findsOneWidget);
    expect(find.text('Dr. Anna Herz'), findsNothing);
  });
}
