import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/appointments/data/appointment_repository.dart';
import 'package:gesundheitplus/src/features/appointments/presentation/appointments_screen.dart';

void main() {
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
