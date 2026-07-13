import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Portrait viewport helpers for aspect-ratio preview masking.
class CameraPreviewViewport {
  const CameraPreviewViewport._();

  /// Native-style sizing: always use full available width (e.g. 16:9 edge-to-edge).
  static Size sizeForFillWidth({
    required BoxConstraints constraints,
    required double widthOverHeight,
  }) {
    final double width = constraints.maxWidth;
    final double height = width / widthOverHeight;
    return Size(width, height);
  }

  /// Largest box that fits entirely inside [constraints].
  static Size sizeFor({
    required BoxConstraints constraints,
    required double widthOverHeight,
  }) {
    final double maxWidth = constraints.maxWidth;
    final double maxHeight = constraints.maxHeight;

    double width = maxWidth;
    double height = width / widthOverHeight;

    if (height > maxHeight) {
      height = maxHeight;
      width = height * widthOverHeight;
    }

    return Size(width, height);
  }
}

/// Top/bottom letterbox bars outside the active preview viewport.
class CameraPreviewViewportOverlay extends StatelessWidget {
  const CameraPreviewViewportOverlay({
    super.key,
    required this.widthOverHeight,
    required this.alignment,
    this.fillWidth = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  final double widthOverHeight;
  final Alignment alignment;
  final bool fillWidth;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size viewport = fillWidth
            ? CameraPreviewViewport.sizeForFillWidth(
                constraints: constraints,
                widthOverHeight: widthOverHeight,
              )
            : CameraPreviewViewport.sizeFor(
                constraints: constraints,
                widthOverHeight: widthOverHeight,
              );

        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        final double viewportWidth = math.min(viewport.width, maxWidth);
        final double viewportHeight = viewport.height;

        return IgnorePointer(
          child: TweenAnimationBuilder<Size>(
            tween: Tween<Size>(
              end: Size(viewportWidth, viewportHeight),
            ),
            duration: duration,
            curve: curve,
            builder: (BuildContext context, Size animatedSize, Widget? _) {
              final Offset origin = _viewportOrigin(
                containerWidth: maxWidth,
                containerHeight: maxHeight,
                viewportWidth: animatedSize.width,
                viewportHeight: animatedSize.height,
                alignment: alignment,
              );
              final double bottomBarTop = origin.dy + animatedSize.height;

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (origin.dy > 0)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: origin.dy,
                      child: const ColoredBox(color: Colors.black54),
                    ),
                  if (bottomBarTop < maxHeight)
                    Positioned(
                      top: bottomBarTop,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: const ColoredBox(color: Colors.black54),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static Offset _viewportOrigin({
    required double containerWidth,
    required double containerHeight,
    required double viewportWidth,
    required double viewportHeight,
    required Alignment alignment,
  }) {
    final double dx =
        (containerWidth - viewportWidth) * ((alignment.x + 1) / 2);
    final double dy =
        (containerHeight - math.min(viewportHeight, containerHeight)) *
            ((alignment.y + 1) / 2);
    return Offset(dx, dy);
  }
}
