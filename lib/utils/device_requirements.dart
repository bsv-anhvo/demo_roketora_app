import 'package:demo_roketota_app/core/extensions/context_extension.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:flutter/material.dart';
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

enum _SettingsAction { app, location }

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

  static Future<void> showLocationIssue(
      BuildContext context,
      LocationRequirementStatus status,
      ) async {
    final _RequirementMessage? message = switch (status) {
      LocationRequirementStatus.serviceDisabled => _RequirementMessage(
        title: Strings.labelGPSIsTurnedOff,
        body: Strings.msgGPSIsTurnedOff,
        openSettingsAction: _SettingsAction.location,
      ),
      LocationRequirementStatus.permissionDenied => _RequirementMessage(
        title: Strings.labelLocationPermissionRequired,
        body: Strings.msgLocationPermissionRequired,
      ),
      LocationRequirementStatus.permissionPermanentlyDenied =>
          _RequirementMessage(
            title: Strings.labelLocationPermissionRequired,
            body: Strings.msgLocationAccessWasDenied,
            openSettingsAction: _SettingsAction.app,
          ),
      LocationRequirementStatus.ready => null,
    };

    if (message == null || !context.mounted) return;
    await _showDialog(context, message);
  }

  static Future<void> showCameraIssue(
      BuildContext context,
      CameraRequirementStatus status,
      ) async {
    final _RequirementMessage? message = switch (status) {
      CameraRequirementStatus.cameraDenied => _RequirementMessage(
        title: Strings.labelCameraPermissionRequired,
        body: Strings.msgAllowCameraAccessToContinue,
      ),
      CameraRequirementStatus.cameraPermanentlyDenied => _RequirementMessage(
        title: Strings.labelCameraPermissionRequired,
        body: Strings.msgCameraAccessWasDenied,
        openSettingsAction: _SettingsAction.app,
      ),
      CameraRequirementStatus.microphoneDenied => _RequirementMessage(
        title: Strings.labelMicrophonePermissionRequired,
        body: Strings.msgAllowMicrophoneAccessToRecordVideoWithAudio,
      ),
      CameraRequirementStatus.microphonePermanentlyDenied =>
          _RequirementMessage(
            title: Strings.labelMicrophonePermissionRequired,
            body: Strings.msgMicrophoneAccessWasDenied,
            openSettingsAction: _SettingsAction.app,
          ),
      CameraRequirementStatus.ready => null,
    };

    if (message == null || !context.mounted) return;
    await _showDialog(context, message);
  }

  static Future<void> _showDialog(
      BuildContext context,
      _RequirementMessage message,
      ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.title),
        content: Text(message.body),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(Strings.labelActionOk),
          ),
          if (message.openSettingsAction != null)
            TextButton(
              onPressed: () async {
                context.pop();
                await _openSettings(message.openSettingsAction!);
              },
              child: Text(Strings.labelActionOpenSettings),
            ),
        ],
      ),
    );
  }

  static Future<void> _openSettings(_SettingsAction action) async {
    switch (action) {
      case _SettingsAction.app:
        await openAppSettings();
      case _SettingsAction.location:
        await Geolocator.openLocationSettings();
    }
  }
}

class _RequirementMessage {
  const _RequirementMessage({
    required this.title,
    required this.body,
    this.openSettingsAction,
  });

  final String title;
  final String body;
  final _SettingsAction? openSettingsAction;
}
