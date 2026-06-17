import 'package:demo_roketota_app/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

class VideoRecordElapsedTimer extends StatelessWidget {
  const VideoRecordElapsedTimer({
    super.key,
    required this.elapsed,
    required this.maxDuration,
  });

  final Duration elapsed;
  final Duration maxDuration;

  String _format(Duration duration) {
    final int seconds = duration.inSeconds.clamp(0, maxDuration.inSeconds);
    return '0:${seconds.toString().padLeft(2, '0')}';
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
            const SizedBox(width: 8),
            Text(
              sprintf(Strings.labelTimeRecord, [_format(elapsed), _format(maxDuration)]),
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
