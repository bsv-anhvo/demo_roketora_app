import 'package:flutter/material.dart';

class VideoTransportControls extends StatelessWidget {
  const VideoTransportControls({
    super.key,
    required this.isPlaying,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
  });

  final bool isPlaying;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  static const double _sideButtonSize = 40;
  static const double _centerButtonSize = 48;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TransportIconButton(
              icon: Icons.skip_previous_rounded,
              size: _sideButtonSize,
              iconSize: 26,
              tooltip: 'Previous',
              onPressed: onPrevious,
            ),
            _TransportIconButton(
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: _centerButtonSize,
              iconSize: 30,
              tooltip: isPlaying ? 'Pause' : 'Play',
              onPressed: onPlayPause,
              highlighted: true,
            ),
            _TransportIconButton(
              icon: Icons.skip_next_rounded,
              size: _sideButtonSize,
              iconSize: 26,
              tooltip: 'Next',
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportIconButton extends StatelessWidget {
  const _TransportIconButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final String tooltip;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: highlighted
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: Size(size, size),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: iconSize),
      ),
    );
  }
}
