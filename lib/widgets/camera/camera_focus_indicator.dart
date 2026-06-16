import 'package:flutter/material.dart';

/// Tap-to-focus frame shown on the camera preview.
class CameraFocusIndicator extends StatelessWidget {
  const CameraFocusIndicator({
    super.key,
    required this.position,
  });

  final Offset position;

  static const double _targetSize = 68;
  static const double _cornerLength = 16;
  static const double _strokeWidth = 2.5;
  static const Color _color = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(position),
        tween: Tween<double>(begin: 1.25, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (_, scale, child) {
          return CustomPaint(
            painter: _CameraFocusPainter(
              tapPosition: position,
              rectSize: _targetSize * scale,
              cornerLength: _cornerLength * scale,
              strokeWidth: _strokeWidth,
              color: _color,
            ),
          );
        },
      ),
    );
  }
}

class _CameraFocusPainter extends CustomPainter {
  const _CameraFocusPainter({
    required this.tapPosition,
    required this.rectSize,
    required this.cornerLength,
    required this.strokeWidth,
    required this.color,
  });

  final Offset tapPosition;
  final double rectSize;
  final double cornerLength;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double left = tapPosition.dx - rectSize / 2;
    final double top = tapPosition.dy - rectSize / 2;
    final double right = left + rectSize;
    final double bottom = top + rectSize;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top)
        ..lineTo(left + cornerLength, top),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, top)
        ..lineTo(right, top)
        ..lineTo(right, top + cornerLength),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(right, bottom - cornerLength)
        ..lineTo(right, bottom)
        ..lineTo(right - cornerLength, bottom),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(left + cornerLength, bottom)
        ..lineTo(left, bottom)
        ..lineTo(left, bottom - cornerLength),
      paint,
    );

    canvas.drawCircle(
      tapPosition,
      3,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CameraFocusPainter oldDelegate) {
    return tapPosition != oldDelegate.tapPosition ||
        rectSize != oldDelegate.rectSize;
  }
}
