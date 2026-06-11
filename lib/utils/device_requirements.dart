import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationRequirementStatus {
  ready,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
}

enum CameraRequirementStatus {
  ready,
  cameraDenied,
  cameraPermanentlyDenied,
  microphoneDenied,
  microphonePermanentlyDenied,
}

class DeviceRequirements {
  const DeviceRequirements._();

  static Future<LocationRequirementStatus> checkLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationRequirementStatus.serviceDisabled;
    }

    final LocationPermission permission = await Geolocator.checkPermission();
    return _mapLocationPermission(permission);
  }

  static Future<LocationRequirementStatus> ensureLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationRequirementStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return _mapLocationPermission(permission);
  }

  static Future<CameraRequirementStatus> ensureCamera({
    required bool needsMicrophone,
  }) async {
    PermissionStatus camera = await Permission.camera.status;
    if (!camera.isGranted) {
      camera = await Permission.camera.request();
      if (!camera.isGranted) {
        return camera.isPermanentlyDenied
            ? CameraRequirementStatus.cameraPermanentlyDenied
            : CameraRequirementStatus.cameraDenied;
      }
    }

    if (!needsMicrophone) {
      return CameraRequirementStatus.ready;
    }

    PermissionStatus microphone = await Permission.microphone.status;
    if (!microphone.isGranted) {
      microphone = await Permission.microphone.request();
      if (!microphone.isGranted) {
        return microphone.isPermanentlyDenied
            ? CameraRequirementStatus.microphonePermanentlyDenied
            : CameraRequirementStatus.microphoneDenied;
      }
    }

    return CameraRequirementStatus.ready;
  }

  static LocationRequirementStatus _mapLocationPermission(
    LocationPermission permission,
  ) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        LocationRequirementStatus.ready,
      LocationPermission.denied =>
        LocationRequirementStatus.permissionDenied,
      LocationPermission.deniedForever =>
        LocationRequirementStatus.permissionPermanentlyDenied,
      LocationPermission.unableToDetermine =>
        LocationRequirementStatus.permissionDenied,
    };
  }
}
