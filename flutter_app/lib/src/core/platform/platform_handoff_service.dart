import 'package:url_launcher/url_launcher.dart';

class PlatformHandoffService {
  const PlatformHandoffService();

  static Uri smsUri(String phone, String body) =>
      Uri(scheme: 'sms', path: phone, queryParameters: {'body': body});

  static Uri telUri(String phone) => Uri(scheme: 'tel', path: phone);

  Future<bool> launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
