import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/platform/platform_handoff_service.dart';

void main() {
  test('builds sms URI with emergency body', () {
    final uri = PlatformHandoffService.smsUri('+491234', 'Ich brauche Hilfe');
    expect(uri.toString(), 'sms:+491234?body=Ich+brauche+Hilfe');
  });

  test('builds tel URI', () {
    final uri = PlatformHandoffService.telUri('+491234');
    expect(uri.toString(), 'tel:+491234');
  });
}
