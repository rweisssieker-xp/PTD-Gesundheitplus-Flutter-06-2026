import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/notifications/data/notification_center_repository.dart';
import 'package:gesundheitplus/src/features/notifications/presentation/notification_center_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets('shows local notification scheduling state', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    await NotificationCenterRepository(db).addNotification(
      title: 'Erinnerung pruefen',
      body: 'Termin muss neu geplant werden',
      category: 'appointment',
      status: LocalNotificationStatus.needsReschedule,
      statusDetail: 'Zeitpunkt liegt in der Vergangenheit',
    );
    await NotificationCenterRepository(db).addNotification(
      title: 'Wichtige Warnung',
      body: 'Bitte sofort pruefen',
      category: 'warning',
      status: LocalNotificationStatus.systemBlocked,
      statusDetail: 'System blockiert',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: MaterialApp(
          home: NotificationCenterScreen(
            permissionStatus: () async => PermissionStatus.granted,
            openSettings: () async => true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Benachrichtigungen'), findsOneWidget);
    expect(find.text('Ungelesene Benachrichtigungen'), findsOneWidget);
    expect(find.text('1 dringende'), findsOneWidget);
    expect(find.text('Alle (2)'), findsOneWidget);
    expect(find.text('Ungelesen (2)'), findsOneWidget);
    expect(find.text('Wichtig (1)'), findsOneWidget);
    expect(find.text('Alle als gelesen'), findsOneWidget);
    expect(find.text('Alle löschen'), findsOneWidget);
    expect(find.text('Erinnerung pruefen'), findsOneWidget);
    expect(find.text('Wichtige Warnung'), findsOneWidget);
    expect(find.text('Neu planen'), findsOneWidget);
    expect(find.text('Zeitpunkt liegt in der Vergangenheit'), findsOneWidget);

    await tester.tap(find.text('Wichtig (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Wichtige Warnung'), findsOneWidget);
    expect(find.text('Erinnerung pruefen'), findsNothing);

    await tester.tap(find.text('Alle als gelesen'));
    await tester.pumpAndSettle();

    expect(find.text('Ungelesen (0)'), findsOneWidget);
  });

  testWidgets('opens system settings when notifications are blocked', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    var settingsOpened = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
        child: MaterialApp(
          home: NotificationCenterScreen(
            permissionStatus: () async => PermissionStatus.permanentlyDenied,
            openSettings: () async {
              settingsOpened = true;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Benachrichtigungen blockiert'), findsOneWidget);
    expect(find.textContaining('Systemeinstellungen'), findsOneWidget);

    await tester.tap(find.text('Einstellungen oeffnen'));
    await tester.pumpAndSettle();

    expect(settingsOpened, isTrue);
  });
}
