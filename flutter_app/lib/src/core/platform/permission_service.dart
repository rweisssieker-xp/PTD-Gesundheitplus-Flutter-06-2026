import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  const PermissionService();

  Future<PermissionStatus> notificationStatus() {
    return Permission.notification.status;
  }

  Future<bool> ensureNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> ensureLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> ensureCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> ensurePhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  Future<bool> openSystemSettings() {
    return openAppSettings();
  }
}
