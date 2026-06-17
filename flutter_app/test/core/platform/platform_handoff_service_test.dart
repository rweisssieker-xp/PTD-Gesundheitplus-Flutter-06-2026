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

  test('builds whatsapp app URI with normalized phone', () {
    final uri = PlatformHandoffService.whatsappUri(
      '+49 176 123456',
      'Ich brauche Hilfe',
    );
    expect(
      uri.toString(),
      'whatsapp://send?phone=49176123456&text=Ich+brauche+Hilfe',
    );
  });

  test('builds telegram URI from handle', () {
    final uri = PlatformHandoffService.telegramUri('@anna_hilfe');
    expect(uri.toString(), 'tg://resolve?domain=anna_hilfe');
  });

  test('builds telegram URI from t.me link', () {
    final uri = PlatformHandoffService.telegramUri('https://t.me/anna_hilfe');
    expect(uri.toString(), 'tg://resolve?domain=anna_hilfe');
  });

  test('builds telegram URI from phone-like target', () {
    final uri = PlatformHandoffService.telegramUri('+49 176 123456');
    expect(uri.toString(), 'tg://resolve?phone=49176123456');
  });
}
