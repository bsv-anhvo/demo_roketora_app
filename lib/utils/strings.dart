import 'package:demo_roketota_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Backward-compatible access to localized strings.
///
/// Strings are bound from [MaterialApp.builder] on each frame.
/// Outside widget tree, Japanese fallback is used.
class Strings {
  static AppLocalizations? _l10n;

  static void bind(AppLocalizations l10n) => _l10n = l10n;

  static AppLocalizations get _l =>
      _l10n ?? lookupAppLocalizations(const Locale('ja'));

  static String get labelApp => _l.labelApp;
  static String get labelDeleteVideoConfirm => _l.labelDeleteVideoConfirm;
  static String get labelDeletePhotoConfirm => _l.labelDeletePhotoConfirm;
  static String get labelVideoPreview => _l.labelVideoPreview;
  static String get labelPhotoPreview => _l.labelPhotoPreview;
  static String get labelTakePhoto => _l.labelTakePhoto;
  static String get labelRecordVideo => _l.labelRecordVideo;
  static String get labelGPSIsTurnedOff => _l.labelGPSIsTurnedOff;
  static String get labelLocationPermissionRequired => _l.labelLocationPermissionRequired;
  static String get labelCameraPermissionRequired => _l.labelCameraPermissionRequired;
  static String get labelMicrophonePermissionRequired => _l.labelMicrophonePermissionRequired;
  static String get labelPhotoResolution => _l.labelPhotoResolution;
  static String get labelAspectRatio => _l.labelAspectRatio;
  static String get labelVideoResolution => _l.labelVideoResolution;
  static String get labelFrameRate => _l.labelFrameRate;
  static String get labelExposure => _l.labelExposure;
  static String get labelFilter => _l.labelFilter;
  static String get labelPortrait => _l.labelPortrait;
  static String get labelResolution => _l.labelResolution;
  static String get labelFps => _l.labelFps;
  static String get labelHoldToRecordVideo => _l.labelHoldToRecordVideo;
  static String get labelRecording => _l.labelRecording;
  static String get labelOriginal => _l.labelOriginal;

  static String get labelActionCancel => _l.labelActionCancel;
  static String get labelActionDelete => _l.labelActionDelete;
  static String get labelActionSave => _l.labelActionSave;
  static String get labelActionOk => _l.labelActionOk;
  static String get labelActionOpenSettings => _l.labelActionOpenSettings;
  static String get labelEditPhoto => _l.labelEditPhoto;

  static String get msgDeleteVideoConfirm => _l.msgDeleteVideoConfirm;
  static String get msgDeletePhotoConfirm => _l.msgDeletePhotoConfirm;
  static String get msgLocationPermissionOrGPSIsNotReady => _l.msgLocationPermissionOrGPSIsNotReady;
  static String get msgCapturing => _l.msgCapturing;
  static String get msgProcessingVideo => _l.msgProcessingVideo;
  static String get msgDeleting => _l.msgDeleting;
  static String get msgSaving => _l.msgSaving;
  static String get msgGPSIsTurnedOff => _l.msgGPSIsTurnedOff;
  static String get msgLocationPermissionRequired => _l.msgLocationPermissionRequired;
  static String get msgLocationAccessWasDenied => _l.msgLocationAccessWasDenied;
  static String get msgAllowCameraAccessToContinue => _l.msgAllowCameraAccessToContinue;
  static String get msgCameraAccessWasDenied => _l.msgCameraAccessWasDenied;
  static String get msgAllowMicrophoneAccessToRecordVideoWithAudio => _l.msgAllowMicrophoneAccessToRecordVideoWithAudio;
  static String get msgMicrophoneAccessWasDenied => _l.msgMicrophoneAccessWasDenied;
  static String get msgLoadingVideo => _l.msgLoadingVideo;
  static String get msgDeleted => _l.msgDeleted;
  static String get msgVideoSaved => _l.msgVideoSaved;
  static String get msgPhotoSaved => _l.msgPhotoSaved;
  static String get msgOriginalFileIsMissing => _l.msgOriginalFileIsMissing;
  static String get msgCouldNotSaveToGallery => _l.msgCouldNotSaveToGallery;
  static String get msgCouldNotSaveVideo => _l.msgCouldNotSaveVideo;
  static String get msgFailedToExtractVideoFrames => _l.msgFailedToExtractVideoFrames;
  static String get msgNoFramesExtractedFromVideo => _l.msgNoFramesExtractedFromVideo;
  static String get msgFailedToEncodeFilteredVideo => _l.msgFailedToEncodeFilteredVideo;

  static String labelTimeRecord(String current, String max) => _l.labelTimeRecord(current, max);
  static String msgRecordingFailed(String error) => _l.msgRecordingFailed(error);
  static String msgCaptureFailed(String error) => _l.msgCaptureFailed(error);
  static String msgUnableToPlayVideo(String error) => _l.msgUnableToPlayVideo(error);
  static String msgDecodeImageFailed(String path) => _l.msgDecodeImageFailed(path);
}
