import 'dart:io';

import 'package:demo_roketota_app/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'package:video_player/video_player.dart';

class AppVideoPreview extends StatefulWidget {
  const AppVideoPreview({
    super.key,
    required this.videoPath,
  });

  final String videoPath;

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
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _errorMessage = sprintf(Strings.msgUnableToPlayVideo, [error]));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
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
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text(
              Strings.msgLoadingVideo,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    final Size videoSize = controller.value.size;
    final double aspectRatio = videoSize.width > 0 && videoSize.height > 0
        ? videoSize.width / videoSize.height
        : 9 / 16;

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final Duration position = controller.value.position;
              final Duration duration = controller.value.duration;

              return Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    },
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: position.inMilliseconds
                          .clamp(0, duration.inMilliseconds)
                          .toDouble(),
                      min: 0,
                      max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                      activeColor: Colors.white,
                      onChanged: (value) {
                        controller.seekTo(
                          Duration(milliseconds: value.round()),
                        );
                      },
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
        Text(
          '${videoSize.width.toInt()}x${videoSize.height.toInt()}',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
