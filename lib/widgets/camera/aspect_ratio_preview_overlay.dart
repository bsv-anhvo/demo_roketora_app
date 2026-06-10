import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws animated black bars below a portrait viewport on top of the preview.
/// Used only when the native preview cannot express the ratio (e.g. 1:1 on Android).
class AspectRatioPreviewOverlay extends StatelessWidget {
  const AspectRatioPreviewOverlay({
    super.key,
    required this.heightOverWidth,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  final double heightOverWidth;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double viewportHeight = math.min(
          constraints.maxWidth * heightOverWidth,
          constraints.maxHeight,
        );

        return IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: viewportHeight),
            duration: duration,
            curve: curve,
            builder: (context, animatedHeight, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: animatedHeight,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: const ColoredBox(color: Colors.black),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
