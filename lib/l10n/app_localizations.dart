import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @labelApp.
  ///
  /// In en, this message translates to:
  /// **'Roketora Camera Demo'**
  String get labelApp;

  /// No description provided for @labelDeleteVideoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete video?'**
  String get labelDeleteVideoConfirm;

  /// No description provided for @labelDeletePhotoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete photo?'**
  String get labelDeletePhotoConfirm;

  /// No description provided for @labelVideoPreview.
  ///
  /// In en, this message translates to:
  /// **'Video Preview'**
  String get labelVideoPreview;

  /// No description provided for @labelPhotoPreview.
  ///
  /// In en, this message translates to:
  /// **'Photo Preview'**
  String get labelPhotoPreview;

  /// No description provided for @labelTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get labelTakePhoto;

  /// No description provided for @labelRecordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record Video'**
  String get labelRecordVideo;

  /// No description provided for @labelGPSIsTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'GPS is turned off'**
  String get labelGPSIsTurnedOff;

  /// No description provided for @labelLocationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get labelLocationPermissionRequired;

  /// No description provided for @labelCameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get labelCameraPermissionRequired;

  /// No description provided for @labelMicrophonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get labelMicrophonePermissionRequired;

  /// No description provided for @labelPhotoResolution.
  ///
  /// In en, this message translates to:
  /// **'Photo Resolution'**
  String get labelPhotoResolution;

  /// No description provided for @labelAspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Aspect Ratio'**
  String get labelAspectRatio;

  /// No description provided for @labelVideoResolution.
  ///
  /// In en, this message translates to:
  /// **'Video Resolution'**
  String get labelVideoResolution;

  /// No description provided for @labelFrameRate.
  ///
  /// In en, this message translates to:
  /// **'Frame Rate (FPS)'**
  String get labelFrameRate;

  /// No description provided for @labelExposure.
  ///
  /// In en, this message translates to:
  /// **'Exposure'**
  String get labelExposure;

  /// No description provided for @labelFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get labelFilter;

  /// No description provided for @labelPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get labelPortrait;

  /// No description provided for @labelResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get labelResolution;

  /// No description provided for @labelFps.
  ///
  /// In en, this message translates to:
  /// **'FPS'**
  String get labelFps;

  /// No description provided for @labelBitrate.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get labelBitrate;

  /// No description provided for @labelVideoBitrate.
  ///
  /// In en, this message translates to:
  /// **'Video Bitrate'**
  String get labelVideoBitrate;

  /// No description provided for @labelTimeRecord.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max}'**
  String labelTimeRecord(String current, String max);

  /// No description provided for @labelHoldToRecordVideo.
  ///
  /// In en, this message translates to:
  /// **'Hold button to record'**
  String get labelHoldToRecordVideo;

  /// No description provided for @labelRecording.
  ///
  /// In en, this message translates to:
  /// **'REC'**
  String get labelRecording;

  /// No description provided for @labelActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get labelActionCancel;

  /// No description provided for @labelActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get labelActionDelete;

  /// No description provided for @labelActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get labelActionSave;

  /// No description provided for @labelActionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get labelActionOk;

  /// No description provided for @labelActionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get labelActionOpenSettings;

  /// No description provided for @labelEditPhoto.
  ///
  /// In en, this message translates to:
  /// **'Edit photo'**
  String get labelEditPhoto;

  /// No description provided for @msgDeleteVideoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this video?'**
  String get msgDeleteVideoConfirm;

  /// No description provided for @msgDeletePhotoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this photo?'**
  String get msgDeletePhotoConfirm;

  /// No description provided for @msgLocationPermissionOrGPSIsNotReady.
  ///
  /// In en, this message translates to:
  /// **'Location permission or GPS is not ready. Tap to check again.'**
  String get msgLocationPermissionOrGPSIsNotReady;

  /// No description provided for @msgCapturing.
  ///
  /// In en, this message translates to:
  /// **'Capturing...'**
  String get msgCapturing;

  /// No description provided for @msgProcessingVideo.
  ///
  /// In en, this message translates to:
  /// **'Processing video...'**
  String get msgProcessingVideo;

  /// No description provided for @msgDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get msgDeleting;

  /// No description provided for @msgSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get msgSaving;

  /// No description provided for @msgGPSIsTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to use this app.'**
  String get msgGPSIsTurnedOff;

  /// No description provided for @msgLocationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to continue.'**
  String get msgLocationPermissionRequired;

  /// No description provided for @msgLocationAccessWasDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access was denied. Open Settings to allow it.'**
  String get msgLocationAccessWasDenied;

  /// No description provided for @msgAllowCameraAccessToContinue.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access to continue.'**
  String get msgAllowCameraAccessToContinue;

  /// No description provided for @msgCameraAccessWasDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access was denied. Open Settings to allow it.'**
  String get msgCameraAccessWasDenied;

  /// No description provided for @msgAllowMicrophoneAccessToRecordVideoWithAudio.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access to record video with audio.'**
  String get msgAllowMicrophoneAccessToRecordVideoWithAudio;

  /// No description provided for @msgMicrophoneAccessWasDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access was denied. Open Settings to allow it.'**
  String get msgMicrophoneAccessWasDenied;

  /// No description provided for @msgRecordingFailed.
  ///
  /// In en, this message translates to:
  /// **'Recording failed: {error}'**
  String msgRecordingFailed(String error);

  /// No description provided for @msgCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Capture failed: {error}'**
  String msgCaptureFailed(String error);

  /// No description provided for @msgUnableToPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Unable to play video: {error}'**
  String msgUnableToPlayVideo(String error);

  /// No description provided for @msgLoadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get msgLoadingVideo;

  /// No description provided for @msgDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get msgDeleted;

  /// No description provided for @msgVideoSaved.
  ///
  /// In en, this message translates to:
  /// **'Video saved'**
  String get msgVideoSaved;

  /// No description provided for @msgPhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo saved'**
  String get msgPhotoSaved;

  /// No description provided for @msgDecodeImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot decode image: {path}'**
  String msgDecodeImageFailed(String path);

  /// No description provided for @msgOriginalFileIsMissing.
  ///
  /// In en, this message translates to:
  /// **'Could not save photo. Original file is missing.'**
  String get msgOriginalFileIsMissing;

  /// No description provided for @msgCouldNotSaveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Could not save to Gallery.'**
  String get msgCouldNotSaveToGallery;

  /// No description provided for @msgCouldNotSaveVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not save video. Please try again.'**
  String get msgCouldNotSaveVideo;

  /// No description provided for @msgFailedToExtractVideoFrames.
  ///
  /// In en, this message translates to:
  /// **'Failed to extract video frames'**
  String get msgFailedToExtractVideoFrames;

  /// No description provided for @msgNoFramesExtractedFromVideo.
  ///
  /// In en, this message translates to:
  /// **'No frames extracted from video'**
  String get msgNoFramesExtractedFromVideo;

  /// No description provided for @msgFailedToEncodeFilteredVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to encode filtered video'**
  String get msgFailedToEncodeFilteredVideo;

  /// No description provided for @labelOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get labelOriginal;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
