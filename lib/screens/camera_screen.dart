import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/utils/media_path_builder.dart';
import 'package:flutter/material.dart';

enum CameraDemoMode { photo, video }

class CameraScreen extends StatelessWidget {
  const CameraScreen({
    super.key,
    required this.mode,
  });

  final CameraDemoMode mode;

  @override
  Widget build(BuildContext context) {
    final bool isPhotoMode = mode == CameraDemoMode.photo;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraAwesomeBuilder.awesome(
            saveConfig: isPhotoMode
                ? SaveConfig.photo(pathBuilder: MediaPathBuilder.photoPath)
                : SaveConfig.video(
                    pathBuilder: MediaPathBuilder.videoPath,
                    videoOptions: VideoOptions(
                      enableAudio: true,
                      android: AndroidVideoOptions(
                        bitrate: 6000000,
                        fallbackStrategy: QualityFallbackStrategy.lower,
                      ),
                      ios: CupertinoVideoOptions(fps: 30),
                    ),
                  ),
            sensorConfig: SensorConfig.single(
              sensor: Sensor.position(SensorPosition.back),
              flashMode: FlashMode.auto,
              aspectRatio: CameraAspectRatios.ratio_4_3,
            ),
            enablePhysicalButton: true,
            previewFit: CameraPreviewFit.cover,
            availableFilters: null,
            onMediaCaptureEvent: (event) => _handleCaptureEvent(context, event),
            topActionsBuilder: (state) => AwesomeTopActions(
              state: state,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  isPhotoMode ? 'Take Photo' : 'Video Record',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCaptureEvent(BuildContext context, MediaCapture event) {
    final messenger = ScaffoldMessenger.of(context);

    switch ((event.status, event.isPicture, event.isVideo)) {
      case (MediaCaptureStatus.capturing, true, false):
        messenger.showSnackBar(
          const SnackBar(content: Text('Đang chụp ảnh...')),
        );
      case (MediaCaptureStatus.success, true, false):
        event.captureRequest.when(
          single: (single) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Ảnh đã lưu: ${single.file?.path ?? 'N/A'}'),
                duration: const Duration(seconds: 4),
              ),
            );
          },
          multiple: (_) {},
        );
      case (MediaCaptureStatus.failure, true, false):
        messenger.showSnackBar(
          SnackBar(
            content: Text('Chụp ảnh thất bại: ${event.exception}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      case (MediaCaptureStatus.capturing, false, true):
        messenger.showSnackBar(
          const SnackBar(content: Text('Đang ghi video...')),
        );
      case (MediaCaptureStatus.success, false, true):
        event.captureRequest.when(
          single: (single) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Video đã lưu: ${single.file?.path ?? 'N/A'}'),
                duration: const Duration(seconds: 4),
              ),
            );
          },
          multiple: (_) {},
        );
      case (MediaCaptureStatus.failure, false, true):
        messenger.showSnackBar(
          SnackBar(
            content: Text('Ghi video thất bại: ${event.exception}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      default:
        break;
    }
  }
}
