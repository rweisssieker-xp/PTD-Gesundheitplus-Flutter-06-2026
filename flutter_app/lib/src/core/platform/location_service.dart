import 'package:geolocator/geolocator.dart';

import 'permission_service.dart';

class LocationService {
  const LocationService({PermissionService? permissions})
    : _permissions = permissions ?? const PermissionService();

  final PermissionService _permissions;

  Future<EmergencyLocation?> currentEmergencyLocation() async {
    if (!await _permissions.ensureLocation()) return null;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return EmergencyLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

class EmergencyLocation {
  const EmergencyLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  String get mapsUrl =>
      'https://maps.google.com/?q=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
}
