import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/core/storage/database_provider.dart';
import 'package:gesundheitplus/src/features/emergency/data/emergency_repository.dart';
import 'package:gesundheitplus/src/features/emergency/presentation/emergency_setup_screen.dart';

void main() {
  testWidgets('emergency setup creates verifies and deletes local contacts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
        child: const MaterialApp(home: EmergencySetupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notfallkontakte lokal'), findsOneWidget);
    expect(find.text('Kontakte importieren'), findsOneWidget);
    expect(find.text('Noch keine Kontakte'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Kontakt'));
    await tester.pumpAndSettle();

    expect(find.text('Notfallkontakt'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Name *'),
      'Anna Beispiel',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Beziehung'),
      'Tochter',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Telefon'),
      '+4912345678',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Messenger'),
      '@anna',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Anna Beispiel'), findsOneWidget);
    expect(find.textContaining('Tochter'), findsOneWidget);
    expect(find.textContaining('+4912345678'), findsOneWidget);
    expect(find.textContaining('@anna'), findsOneWidget);

    var contacts = await EmergencyRepository(db).listContacts();
    expect(contacts.single.name, 'Anna Beispiel');
    expect(contacts.single.relationship, 'Tochter');
    expect(contacts.single.phone, '+4912345678');
    expect(contacts.single.messenger, '@anna');
    expect(contacts.single.verified, isFalse);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verifiziert'));
    await tester.pumpAndSettle();

    contacts = await EmergencyRepository(db).listContacts();
    expect(contacts.single.verified, isTrue);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loeschen'));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Kontakte'), findsOneWidget);
    expect(await EmergencyRepository(db).listContacts(), isEmpty);
  });
}
