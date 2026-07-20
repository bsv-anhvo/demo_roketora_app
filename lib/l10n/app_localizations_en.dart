// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get labelApp => 'Roketora Camera Demo';

  @override
  String get labelDeleteVideoConfirm => 'Delete video?';

  @override
  String get labelDeletePhotoConfirm => 'Delete photo?';

  @override
  String get labelVideoPreview => 'Video Preview';

  @override
  String get labelPhotoPreview => 'Photo Preview';

  @override
  String get labelTakePhoto => 'Take Photo';

  @override
  String get labelRecordVideo => 'Record Video';

  @override
  String get labelGPSIsTurnedOff => 'GPS is turned off';

  @override
  String get labelLocationPermissionRequired => 'Location permission required';

  @override
  String get labelCameraPermissionRequired => 'Camera permission required';

  @override
  String get labelMicrophonePermissionRequired =>
      'Microphone permission required';

  @override
  String get labelPhotoResolution => 'Photo Resolution';

  @override
  String get labelAspectRatio => 'Aspect Ratio';

  @override
  String get labelVideoResolution => 'Video Resolution';

  @override
  String get labelFrameRate => 'Frame Rate (FPS)';

  @override
  String get labelExposure => 'Exposure';

  @override
  String get labelFilter => 'Filter';

  @override
  String get labelPortrait => 'Portrait';

  @override
  String get labelResolution => 'Resolution';

  @override
  String get labelFps => 'FPS';

  @override
  String get labelBitrate => 'Bitrate';

  @override
  String get labelVideoBitrate => 'Video Bitrate';

  @override
  String labelTimeRecord(String current, String max) {
    return '$current / $max';
  }

  @override
  String get labelHoldToRecordVideo => 'Hold button to record';

  @override
  String get labelRecording => 'REC';

  @override
  String get labelActionCancel => 'Cancel';

  @override
  String get labelActionDelete => 'Delete';

  @override
  String get labelActionSave => 'Save';

  @override
  String get labelActionOk => 'OK';

  @override
  String get labelActionOpenSettings => 'Open Settings';

  @override
  String get labelEditPhoto => 'Edit photo';

  @override
  String get msgDeleteVideoConfirm => 'Do you want to delete this video?';

  @override
  String get msgDeletePhotoConfirm => 'Do you want to delete this photo?';

  @override
  String get msgLocationPermissionOrGPSIsNotReady =>
      'Location permission or GPS is not ready. Tap to check again.';

  @override
  String get msgCapturing => 'Capturing...';

  @override
  String get msgProcessingVideo => 'Processing video...';

  @override
  String get msgProcessingPhoto => 'Processing photo...';

  @override
  String get msgDeleting => 'Deleting...';

  @override
  String get msgSaving => 'Saving...';

  @override
  String get msgGPSIsTurnedOff => 'Turn on location services to use this app.';

  @override
  String get msgLocationPermissionRequired =>
      'Allow location access to continue.';

  @override
  String get msgLocationAccessWasDenied =>
      'Location access was denied. Open Settings to allow it.';

  @override
  String get msgAllowCameraAccessToContinue =>
      'Allow camera access to continue.';

  @override
  String get msgCameraAccessWasDenied =>
      'Camera access was denied. Open Settings to allow it.';

  @override
  String get msgAllowMicrophoneAccessToRecordVideoWithAudio =>
      'Allow microphone access to record video with audio.';

  @override
  String get msgMicrophoneAccessWasDenied =>
      'Microphone access was denied. Open Settings to allow it.';

  @override
  String msgRecordingFailed(String error) {
    return 'Recording failed: $error';
  }

  @override
  String msgCaptureFailed(String error) {
    return 'Capture failed: $error';
  }

  @override
  String msgUnableToPlayVideo(String error) {
    return 'Unable to play video: $error';
  }

  @override
  String get msgLoadingVideo => 'Loading video...';

  @override
  String get msgDeleted => 'Deleted';

  @override
  String get msgVideoSaved => 'Video saved';

  @override
  String get msgPhotoSaved => 'Photo saved';

  @override
  String msgDecodeImageFailed(String path) {
    return 'Cannot decode image: $path';
  }

  @override
  String get msgOriginalFileIsMissing =>
      'Could not save photo. Original file is missing.';

  @override
  String get msgCouldNotSaveToGallery => 'Could not save to Gallery.';

  @override
  String get msgCouldNotSaveVideo => 'Could not save video. Please try again.';

  @override
  String get msgFailedToExtractVideoFrames => 'Failed to extract video frames';

  @override
  String get msgNoFramesExtractedFromVideo => 'No frames extracted from video';

  @override
  String get msgFailedToEncodeFilteredVideo =>
      'Failed to encode filtered video';

  @override
  String get labelOriginal => 'Original';
}
