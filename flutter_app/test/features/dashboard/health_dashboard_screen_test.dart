import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/dashboard/presentation/health_dashboard_screen.dart';

void main() {
  testWidgets('health dashboard shows local score and PWA quick stats', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    _seedDashboardData(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: HealthDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gesundheits-Dashboard'), findsOneWidget);
    expect(find.text('Ihr Gesundheits-Score'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains('80/100'),
      ),
      findsOneWidget,
    );
    expect(find.text('Ausgezeichnet'), findsOneWidget);
    expect(find.text('Medikamente'), findsOneWidget);
    expect(find.text('Termine'), findsOneWidget);
    expect(find.text('Allergien'), findsOneWidget);
    expect(find.text('Dokumente'), findsOneWidget);
    expect(find.text('Vitalwerte'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('1 kritische Allergie(n) dokumentiert'), findsOneWidget);
    expect(find.text('1 offene Vorsorgeaufgabe(n)'), findsOneWidget);
    expect(find.text('Medikamenten-Treue (diese Woche)'), findsOneWidget);
    expect(find.text('Durchschnitt: 95% - Ausgezeichnet!'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Dokumenten-Verteilung'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dokumenten-Verteilung'), findsOneWidget);
    expect(find.text('Labor'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Anstehende Termine'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Anstehende Termine'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Notfallprofil vorbereitet'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Notfallprofil vorbereitet'), findsOneWidget);
  });
}

void _seedDashboardData(AppDatabase db) {
  final now = DateTime(2026, 6, 18, 12).toIso8601String();
  db.execute(
    '''
    INSERT INTO medications (
      id, name, dosage, frequency, active, reminder_times_json, created_at, updated_at
    ) VALUES ('m1', 'Amoxicillin', '1 Tablette', '1x täglich', 1, '[]', ?, ?)
    ''',
    [now, now],
  );
  db.execute(
    '''
    INSERT INTO appointments (
      id, title, starts_at, status, created_at, updated_at
    ) VALUES ('a1', 'Kontrolle', ?, 'Geplant', ?, ?)
    ''',
    [now, now, now],
  );
  db.execute(
    '''
    INSERT INTO allergies (
      id, substance, category, severity, created_at, updated_at
    ) VALUES ('al1', 'Penicillin', 'Medikament', 'Schwer', ?, ?)
    ''',
    [now, now],
  );
  db.execute(
    '''
    INSERT INTO health_documents (
      id, title, category, local_path, captured_at, created_at, updated_at
    ) VALUES ('d1', 'Labor', 'Labor', '/tmp/labor.pdf', ?, ?, ?)
    ''',
    [now, now, now],
  );
  db.execute(
    '''
    INSERT INTO blood_pressure_logs (
      id, systolic, diastolic, measured_at, created_at, updated_at
    ) VALUES ('bp1', 120, 80, ?, ?, ?)
    ''',
    [now, now, now],
  );
  db.execute(
    '''
    INSERT INTO weight_logs (
      id, weight_kg, measured_at, created_at, updated_at
    ) VALUES ('w1', 80, ?, ?, ?)
    ''',
    [now, now, now],
  );
  db.execute(
    '''
    INSERT INTO vaccinations (
      id, vaccine_name, vaccinated_at, created_at, updated_at
    ) VALUES ('v1', 'Tetanus', ?, ?, ?), ('v2', 'Grippe', ?, ?, ?)
    ''',
    [now, now, now, now, now, now],
  );
  db.execute(
    '''
    INSERT INTO preventive_care_items (
      id, title, category, due_at, status, created_at, updated_at
    ) VALUES ('p1', 'Check-up', 'Vorsorge', ?, 'offen', ?, ?)
    ''',
    [now, now, now],
  );
  db.execute(
    '''
    INSERT INTO emergency_contacts (
      id, name, phone, verified, created_at, updated_at
    ) VALUES ('e1', 'Anna', '+49123', 1, ?, ?)
    ''',
    [now, now],
  );
  db.execute(
    '''
    INSERT INTO notifications (
      id, title, body, category, read, created_at
    ) VALUES ('n1', 'Hinweis', 'Bitte prüfen', 'warning', 0, ?)
    ''',
    [now],
  );
}
