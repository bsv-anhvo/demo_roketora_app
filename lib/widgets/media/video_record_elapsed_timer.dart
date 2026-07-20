import 'package:demo_roketota_app/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class VideoRecordElapsedTimer extends StatelessWidget {
  const VideoRecordElapsedTimer({
    super.key,
    required this.elapsed,
    required this.maxDuration,
  });

  final Duration elapsed;
  final Duration maxDuration;

  String _format(Duration duration) {
    final int totalSeconds = duration.inSeconds.clamp(0, maxDuration.inSeconds);
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const Gap(8),
            Text(
              Strings.labelTimeRecord(_format(elapsed), _format(maxDuration)),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
