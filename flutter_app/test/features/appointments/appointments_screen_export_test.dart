import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/appointments/data/appointment_repository.dart';
import 'package:gesundheitplus/src/features/appointments/presentation/appointments_screen.dart';

void main() {
  testWidgets('adds appointment with local reminder state from editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: AppointmentsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Ersten Termin hinzufuegen'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ersten Termin hinzufuegen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Arzt / Behandler *'),
      'Dr. Schmidt',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Fachrichtung'),
      'Kardiologie',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Datum YYYY-MM-DD'),
      '2026-07-02',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Uhrzeit HH:MM'),
      '09:30',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Ort'),
      'Praxis Mitte',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Grund'),
      'Kontrolle',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Schmidt'), findsOneWidget);
    expect(find.text('2.7.2026 • 09:30 Uhr'), findsOneWidget);
    expect(find.text('Kardiologie'), findsOneWidget);
    expect(find.text('Praxis Mitte'), findsOneWidget);
    expect(find.text('Kontrolle'), findsOneWidget);
    expect(find.text('24h Erinnerung'), findsOneWidget);

    final saved = await AppointmentRepository(db).listAppointments();
    expect(saved.single.doctorName, 'Dr. Schmidt');
    expect(saved.single.startsAt, DateTime(2026, 7, 2, 9, 30));
    expect(saved.single.reminderEnabled, isTrue);
    expect(saved.single.reminderHoursBefore, 24);
  });

  testWidgets('shows recovery message when appointment export creation fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = AppointmentRepository(db);
    await repo.saveAppointment(
      repo.newAppointment(
        doctorName: 'Dr. Muster',
        date: DateTime(2026, 7, 2),
        time: '09:30',
        reason: 'Kontrolle',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: MaterialApp(
          home: AppointmentsScreen(
            exportDirectoryProvider: () async =>
                throw StateError('storage unavailable'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Alle Termine exportieren'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('Termine konnten nicht exportiert werden'),
      findsOneWidget,
    );
  });
}
