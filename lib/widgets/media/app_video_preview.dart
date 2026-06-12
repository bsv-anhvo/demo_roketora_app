import 'dart:io';

import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/widgets/media/video_transport_controls.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'package:video_player/video_player.dart';

class AppVideoPreview extends StatefulWidget {
  const AppVideoPreview({
    super.key,
    required this.videoPath,
    this.skipInterval = const Duration(seconds: 10),
  });

  final String videoPath;
  final Duration skipInterval;

  @override
  State<AppVideoPreview> createState() => _AppVideoPreviewState();
}

class _AppVideoPreviewState extends State<AppVideoPreview> {
  VideoPlayerController? _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final VideoPlayerController controller = VideoPlayerController.file(
      File(widget.videoPath),
    );

    try {
      await controller.initialize();
      await controller.setLooping(false);
      controller.addListener(_onControllerUpdate);
      await controller.play();
      if (!mounted) {
        controller.removeListener(_onControllerUpdate);
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error) {
      await controller.dispose();
      if (!mounted) return;
      setState(
        () => _errorMessage = sprintf(Strings.msgUnableToPlayVideo, [error]),
      );
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _togglePlayPause() {
    final VideoPlayerController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
      return;
    }

    final Duration position = controller.value.position;
    final Duration duration = controller.value.duration;
    if (duration > Duration.zero && position >= duration) {
      controller.seekTo(Duration.zero);
    }
    controller.play();
  }

  void _seekRelative(Duration offset) {
    final VideoPlayerController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final Duration duration = controller.value.duration;
    final int targetMs = (controller.value.position + offset).inMilliseconds
        .clamp(0, duration.inMilliseconds);

    controller.seekTo(Duration(milliseconds: targetMs));
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 12),
            Text(
              Strings.msgLoadingVideo,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    final Size videoSize = controller.value.size;
    final double aspectRatio = videoSize.width > 0 && videoSize.height > 0
        ? videoSize.width / videoSize.height
        : 9 / 16;

    final Duration position = controller.value.position;
    final Duration duration = controller.value.duration;
    final int durationMs = duration.inMilliseconds.clamp(1, 1 << 31);
    final bool isPlaying = controller.value.isPlaying;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            children: [
              Text(
                sprintf(
                  Strings.labelTimeRecord,
                  [_formatDuration(position), _formatDuration(duration)],
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Slider(
                value: position.inMilliseconds.clamp(0, durationMs).toDouble(),
                min: 0,
                max: durationMs.toDouble(),
                activeColor: Colors.white,
                inactiveColor: Colors.white24,
                onChanged: (value) {
                  controller.seekTo(
                    Duration(milliseconds: value.round()),
                  );
                },
              ),
              Center(
                child: VideoTransportControls(
                  isPlaying: isPlaying,
                  onPrevious: () => _seekRelative(-widget.skipInterval),
                  onPlayPause: _togglePlayPause,
                  onNext: () => _seekRelative(widget.skipInterval),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
