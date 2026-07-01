// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get labelApp => 'Roketora カメラデモ';

  @override
  String get labelDeleteVideoConfirm => '動画を削除しますか？';

  @override
  String get labelDeletePhotoConfirm => '写真を削除しますか？';

  @override
  String get labelVideoPreview => '動画プレビュー';

  @override
  String get labelPhotoPreview => '写真プレビュー';

  @override
  String get labelTakePhoto => '写真を撮る';

  @override
  String get labelRecordVideo => '動画を録画';

  @override
  String get labelGPSIsTurnedOff => 'GPSがオフです';

  @override
  String get labelLocationPermissionRequired => '位置情報の許可が必要です';

  @override
  String get labelCameraPermissionRequired => 'カメラの許可が必要です';

  @override
  String get labelMicrophonePermissionRequired => 'マイクの許可が必要です';

  @override
  String get labelPhotoResolution => '写真の解像度';

  @override
  String get labelAspectRatio => 'アスペクト比';

  @override
  String get labelVideoResolution => '動画の解像度';

  @override
  String get labelFrameRate => 'フレームレート (FPS)';

  @override
  String get labelExposure => '露出';

  @override
  String get labelFilter => 'フィルター';

  @override
  String get labelPortrait => 'ポートレート';

  @override
  String get labelResolution => '解像度';

  @override
  String get labelFps => 'FPS';

  @override
  String get labelBitrate => 'ビットレート';

  @override
  String get labelVideoBitrate => '動画ビットレート';

  @override
  String labelTimeRecord(String current, String max) {
    return '$current / $max';
  }

  @override
  String get labelHoldToRecordVideo => 'ボタンを長押しして録画';

  @override
  String get labelRecording => '録画中';

  @override
  String get labelActionCancel => 'キャンセル';

  @override
  String get labelActionDelete => '削除';

  @override
  String get labelActionSave => '保存';

  @override
  String get labelActionOk => 'OK';

  @override
  String get labelActionOpenSettings => '設定を開く';

  @override
  String get labelEditPhoto => '写真を編集';

  @override
  String get msgDeleteVideoConfirm => 'この動画を削除しますか？';

  @override
  String get msgDeletePhotoConfirm => 'この写真を削除しますか？';

  @override
  String get msgLocationPermissionOrGPSIsNotReady =>
      '位置情報の許可またはGPSの準備ができていません。タップして再確認してください。';

  @override
  String get msgCapturing => '撮影中...';

  @override
  String get msgProcessingVideo => '動画を処理中...';

  @override
  String get msgDeleting => '削除中...';

  @override
  String get msgSaving => '保存中...';

  @override
  String get msgGPSIsTurnedOff => 'このアプリを使用するには位置情報サービスをオンにしてください。';

  @override
  String get msgLocationPermissionRequired => '続行するには位置情報へのアクセスを許可してください。';

  @override
  String get msgLocationAccessWasDenied => '位置情報へのアクセスが拒否されました。設定から許可してください。';

  @override
  String get msgAllowCameraAccessToContinue => '続行するにはカメラへのアクセスを許可してください。';

  @override
  String get msgCameraAccessWasDenied => 'カメラへのアクセスが拒否されました。設定から許可してください。';

  @override
  String get msgAllowMicrophoneAccessToRecordVideoWithAudio =>
      '音声付き動画を録画するにはマイクへのアクセスを許可してください。';

  @override
  String get msgMicrophoneAccessWasDenied => 'マイクへのアクセスが拒否されました。設定から許可してください。';

  @override
  String msgRecordingFailed(String error) {
    return '録画に失敗しました: $error';
  }

  @override
  String msgCaptureFailed(String error) {
    return '撮影に失敗しました: $error';
  }

  @override
  String msgUnableToPlayVideo(String error) {
    return '動画を再生できません: $error';
  }

  @override
  String get msgLoadingVideo => '動画を読み込み中...';

  @override
  String get msgDeleted => '削除しました';

  @override
  String get msgVideoSaved => '動画を保存しました';

  @override
  String get msgPhotoSaved => '写真を保存しました';

  @override
  String msgDecodeImageFailed(String path) {
    return '画像をデコードできません: $path';
  }

  @override
  String get msgOriginalFileIsMissing => '写真を保存できませんでした。元のファイルが見つかりません。';

  @override
  String get msgCouldNotSaveToGallery => 'ギャラリーに保存できませんでした。';

  @override
  String get msgCouldNotSaveVideo => '動画を保存できませんでした。もう一度お試しください。';

  @override
  String get msgFailedToExtractVideoFrames => '動画フレームの抽出に失敗しました';

  @override
  String get msgNoFramesExtractedFromVideo => '動画からフレームを抽出できませんでした';

  @override
  String get msgFailedToEncodeFilteredVideo => 'フィルター付き動画のエンコードに失敗しました';

  @override
  String get labelOriginal => 'オリジナル';
}
