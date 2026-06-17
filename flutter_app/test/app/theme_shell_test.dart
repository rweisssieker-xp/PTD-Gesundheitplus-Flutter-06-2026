import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/app/gesundheit_app.dart';

void main() {
  testWidgets('renders Gesundheit Plus shell with red header', (tester) async {
    await tester.pumpWidget(const GesundheitApp());
    await tester.pumpAndSettle();

    expect(find.text('Gesundheit Plus'), findsOneWidget);
    final container = tester.widget<Container>(
      find.byKey(const Key('gp-header-red-border')),
    );
    expect(container.color, const Color(0xFFDC2626));
  });
}
