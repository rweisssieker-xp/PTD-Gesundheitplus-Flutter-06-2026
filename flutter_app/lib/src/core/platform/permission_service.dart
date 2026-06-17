import 'package:permission_handler/permission_handler.dart';

class PermissionService {
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

  Future<bool> openSystemSettings() {
    return openAppSettings();
  }
}
