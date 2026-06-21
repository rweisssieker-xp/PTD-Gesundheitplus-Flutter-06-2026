import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/emergency/presentation/emergency_offline_screen.dart';

void main() {
  testWidgets('offline emergency screen shows local PWA parity sections', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    _seedEmergencyData(db);

    tester.view.physicalSize = const Size(430, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: EmergencyOfflineScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline-Notfalldaten'), findsOneWidget);
    expect(find.text('Offline-Notfallprofil bereit'), findsOneWidget);
    expect(find.text('Persönliche Daten'), findsOneWidget);
    expect(find.text('Erika Muster'), findsWidgets);
    expect(find.text('QR-Code für Ersthelfer'), findsOneWidget);
    expect(find.text('Kritische Warnungen'), findsOneWidget);
    expect(
      find.textContaining('Allergie: Penicillin (Schwer)'),
      findsOneWidget,
    );
    expect(find.text('Sofortmaßnahmen'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Aktuelle Medikamente'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Aktuelle Medikamente'), findsOneWidget);
    expect(find.text('ASS (100mg, taeglich)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sperrbildschirm vorbereiten'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sperrbildschirm vorbereiten'), findsOneWidget);
  });

  testWidgets('copies offline emergency QR payload with local records', (
    tester,
  ) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final data = call.arguments as Map<dynamic, dynamic>;
          copiedText = data['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final db = AppDatabase.memory();
    addTearDown(db.close);
    _seedEmergencyData(db);

    tester.view.physicalSize = const Size(430, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: const MaterialApp(home: EmergencyOfflineScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('QR-Daten kopieren'));
    await tester.pumpAndSettle();

    final payload = jsonDecode(copiedText!) as Map<String, dynamic>;

    expect(payload['source'], 'Gesundheit Plus');
    expect(payload['fullName'], 'Erika Muster');
    expect(payload['medications'], contains('ASS (100mg, taeglich)'));
    expect(payload['allergies'], contains('Penicillin (Schwer, Atemnot)'));
    expect(payload['diagnoses'], contains('Asthma'));
    expect(
      payload['contacts'],
      contains(
        allOf(
          containsPair('name', 'Max Kontakt'),
          containsPair('phone', '+491234'),
        ),
      ),
    );
  });
}

void _seedEmergencyData(AppDatabase db) {
  db.execute('''
    INSERT INTO local_profiles (
      id, full_name, date_of_birth, notes, created_at, updated_at
    )
    VALUES ('default', 'Erika Muster', '1970-01-02T00:00:00.000', 'Diabetes Typ 2', 'now', 'now')
  ''');
  db.execute('''
    INSERT INTO medications (
      id, name, dosage, frequency, active, reminder_times_json, created_at, updated_at
    )
    VALUES ('med-1', 'ASS', '100mg', 'taeglich', 1, '[]', 'now', 'now')
  ''');
  db.execute('''
    INSERT INTO allergies (
      id, substance, category, reaction, severity, created_at, updated_at
    )
    VALUES ('allergy-1', 'Penicillin', 'Medikament', 'Atemnot', 'Schwer', 'now', 'now')
  ''');
  db.execute('''
    INSERT INTO medical_history_entries (
      id, category, title, details, active, created_at, updated_at
    )
    VALUES ('history-1', 'Diagnose', 'Asthma', NULL, 1, 'now', 'now')
  ''');
  db.execute('''
    INSERT INTO emergency_contacts (
      id, name, relationship, phone, verified, created_at, updated_at
    )
    VALUES ('contact-1', 'Max Kontakt', 'Partner', '+491234', 1, 'now', 'now')
  ''');
}
