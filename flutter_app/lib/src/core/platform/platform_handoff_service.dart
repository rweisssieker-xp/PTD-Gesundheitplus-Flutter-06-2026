import 'package:url_launcher/url_launcher.dart';

class PlatformHandoffService {
  const PlatformHandoffService();

  static Uri smsUri(String phone, String body) =>
      Uri(scheme: 'sms', path: phone, queryParameters: {'body': body});

  static Uri telUri(String phone) => Uri(scheme: 'tel', path: phone);

  static Uri whatsappUri(String phone, String body) => Uri(
    scheme: 'whatsapp',
    host: 'send',
    queryParameters: {'phone': _whatsappPhone(phone), 'text': body},
  );

  Future<bool> launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _whatsappPhone(String phone) {
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (normalized.startsWith('+')) return normalized.substring(1);
    if (normalized.startsWith('00')) return normalized.substring(2);
    return normalized;
  }
}
