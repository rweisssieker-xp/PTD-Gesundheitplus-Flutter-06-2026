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

    expect(find.text('Erinnerung pruefen'), findsOneWidget);
    expect(find.text('Neu planen'), findsOneWidget);
    expect(find.text('Zeitpunkt liegt in der Vergangenheit'), findsOneWidget);
  });
}
