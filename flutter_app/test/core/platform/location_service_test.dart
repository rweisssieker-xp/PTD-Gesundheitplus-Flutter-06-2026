import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/platform/location_service.dart';

void main() {
  test('formats emergency maps link', () {
    const location = EmergencyLocation(
      latitude: 52.520008,
      longitude: 13.404954,
    );

    expect(location.mapsUrl, 'https://maps.google.com/?q=52.520008,13.404954');
  });
}
