import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// Tap-to-focus frame with an iOS-style vertical exposure slider on its side.
///
/// The focus frame is non-interactive while the sun handle can be dragged
/// vertically to change exposure. The State is reused across taps, so
/// [didUpdateWidget] re-syncs the handle to [exposure] on each new tap.
///
/// When drawn inside camerawesome's scaled preview, pass [previewScale] from
/// [AnalysisPreview.scale] so the overlay keeps a consistent on-screen size.
class CameraFocusIndicator extends StatefulWidget {
  const CameraFocusIndicator({
    super.key,
    required this.position,
    this.previewScale = 1.0,
    this.exposure = 0.5,
    this.onExposureChanged,
  });

  final Offset position;

  /// Cover/contain scale applied to the preview texture by camerawesome.
  final double previewScale;

  /// Normalized exposure in [0, 1]; 0.5 is neutral.
  final double exposure;

  /// Called while dragging the sun handle. Value is normalized [0, 1].
  final ValueChanged<double>? onExposureChanged;

  @override
  State<CameraFocusIndicator> createState() => _CameraFocusIndicatorState();
}

class _CameraFocusIndicatorState extends State<CameraFocusIndicator> {
  static const double _targetSize = 48;
  static const double _cornerLength = 16;
  static const double _strokeWidth = 1.5;

  static const double _trackHeight = 120;
  static const double _sunSize = 26;
  static const double _hitWidth = 44;
  static const double _sliderGap = 10;
  static const double _edgePadding = 8;

  late double _exposure = widget.exposure.clamp(0.0, 1.0);

  double get _sizeFactor {
    final double scale = widget.previewScale;
    if (scale <= 0) return 1;
    return 1 / scale;
  }

  @override
  void didUpdateWidget(CameraFocusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The State is reused across taps (same type, no key). A new tap means a
    // new focus point, which always resets exposure to neutral, so re-sync the
    // local value whenever the tap position or the incoming exposure changes.
    if (widget.position != oldWidget.position ||
        widget.exposure != oldWidget.exposure) {
      _exposure = widget.exposure.clamp(0.0, 1.0);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // primaryDelta is in preview texture coordinates (inside InteractiveViewer),
    // so divide by the scaled track height, not the on-screen design height.
    final double trackHeight = _trackHeight * _sizeFactor;
    if (trackHeight <= 0) return;
    final double next =
        (_exposure - details.primaryDelta! / trackHeight).clamp(0.0, 1.0);
    if (next == _exposure) return;
    setState(() => _exposure = next);
    widget.onExposureChanged?.call(_exposure);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final double maxH = constraints.maxHeight;
        final Offset p = widget.position;
        final double sizeFactor = _sizeFactor;

        final double targetSize = _targetSize * sizeFactor;
        final double cornerLength = _cornerLength * sizeFactor;
        final double strokeWidth = _strokeWidth * sizeFactor;
        final double trackHeight = _trackHeight * sizeFactor;
        final double sunSize = _sunSize * sizeFactor;
        final double hitWidth = _hitWidth * sizeFactor;
        final double sliderGap = _sliderGap * sizeFactor;
        final double edgePadding = _edgePadding * sizeFactor;

        // Prefer the right side; flip to the left when there is no room.
        final double rightLeft = p.dx + targetSize / 2 + sliderGap;
        final bool placeRight = rightLeft + hitWidth <= maxW;
        final double sliderLeft = placeRight
            ? rightLeft
            : p.dx - targetSize / 2 - sliderGap - hitWidth;

        // Keep the track on screen, centered on the tap when possible.
        final double maxTop = (maxH - trackHeight - edgePadding)
            .clamp(edgePadding, double.infinity);
        final double trackTop =
            (p.dy - trackHeight / 2).clamp(edgePadding, maxTop);

        // Fill the preview so hit-testing reaches the handle. Without an
        // explicit size the Stack collapses around the size-less focus painter
        // and would never receive pointer events.
        return SizedBox(
          width: maxW,
          height: maxH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(p),
                  tween: Tween<double>(begin: 1.25, end: 1.0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  builder: (_, anim, child) {
                    return CustomPaint(
                      size: Size(maxW, maxH),
                      painter: _CameraFocusPainter(
                        tapPosition: p,
                        rectSize: targetSize * anim,
                        cornerLength: cornerLength * anim,
                        strokeWidth: strokeWidth,
                        dotRadius: 3 * sizeFactor,
                        color: AppColors.color255_213_79,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: sliderLeft,
                top: trackTop - sunSize / 2,
                width: hitWidth,
                height: trackHeight + sunSize,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: _onDragUpdate,
                  child: _ExposureHandle(
                    exposure: _exposure,
                    trackHeight: trackHeight,
                    sunSize: sunSize,
                    hitWidth: hitWidth,
                    color: AppColors.color255_213_79,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Vertical exposure track with a draggable sun handle.
class _ExposureHandle extends StatelessWidget {
  const _ExposureHandle({
    required this.exposure,
    required this.trackHeight,
    required this.sunSize,
    required this.hitWidth,
    required this.color,
  });

  final double exposure;
  final double trackHeight;
  final double sunSize;
  final double hitWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const List<Shadow> shadows = [
      Shadow(color: Colors.black54, blurRadius: 4),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: hitWidth / 2 - 1,
          top: sunSize / 2,
          bottom: sunSize / 2,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        Positioned(
          left: hitWidth / 2 - sunSize / 2,
          top: (1 - exposure) * trackHeight,
          child: Icon(
            Icons.wb_sunny,
            size: sunSize,
            color: color,
            shadows: shadows,
          ),
        ),
      ],
    );
  }
}

class _CameraFocusPainter extends CustomPainter {
  const _CameraFocusPainter({
    required this.tapPosition,
    required this.rectSize,
    required this.cornerLength,
    required this.strokeWidth,
    required this.dotRadius,
    required this.color,
  });

  final Offset tapPosition;
  final double rectSize;
  final double cornerLength;
  final double strokeWidth;
  final double dotRadius;
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
      dotRadius,
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
