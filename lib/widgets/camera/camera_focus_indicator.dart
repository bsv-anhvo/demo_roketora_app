import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// Tap-to-focus frame with an iOS-style vertical exposure slider on its side.
///
/// The focus frame is non-interactive while the sun handle can be dragged
/// vertically to change exposure. [didUpdateWidget] re-syncs the sun handle
/// when [exposure] changes from outside (e.g. the horizontal exposure bar).
/// The focus frame animation only runs on a new tap position.
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
  static const double _tickLength = 7;
  static const double _strokeWidth = 1.0;

  static const double _trackHeight = 100;
  static const double _sunSize = 26;
  static const double _hitWidth = 44;
  static const double _sliderGap = 10;
  static const double _edgePadding = 8;

  late double _exposure = widget.exposure.clamp(0.0, 1.0);
  bool _showExposureTrack = false;

  double get _sizeFactor {
    final double scale = widget.previewScale;
    if (scale <= 0) return 1;
    return 1 / scale;
  }

  @override
  void didUpdateWidget(CameraFocusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.position != oldWidget.position) {
      _exposure = widget.exposure.clamp(0.0, 1.0);
      _showExposureTrack = false;
    } else if (widget.exposure != oldWidget.exposure) {
      _exposure = widget.exposure.clamp(0.0, 1.0);
      _showExposureTrack = true;
    }
  }

  void _onDragEnd() {
    if (!_showExposureTrack) return;
    setState(() => _showExposureTrack = false);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // primaryDelta is in preview texture coordinates (inside InteractiveViewer),
    // so divide by the scaled track height, not the on-screen design height.
    final double trackHeight = _trackHeight * _sizeFactor;
    if (trackHeight <= 0) return;
    final double next =
        (_exposure - details.primaryDelta! / trackHeight).clamp(0.0, 1.0);
    if (next == _exposure) return;
    setState(() {
      _exposure = next;
      _showExposureTrack = true;
    });
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
        final double tickLength = _tickLength * sizeFactor;
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
                        tickLength: tickLength * anim,
                        strokeWidth: strokeWidth,
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
                  onVerticalDragEnd: (_) => _onDragEnd(),
                  onVerticalDragCancel: _onDragEnd,
                  child: _ExposureHandle(
                    exposure: _exposure,
                    trackHeight: trackHeight,
                    sunSize: sunSize,
                    hitWidth: hitWidth,
                    showTrack: _showExposureTrack,
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
    required this.showTrack,
    required this.color,
  });

  final double exposure;
  final double trackHeight;
  final double sunSize;
  final double hitWidth;
  final bool showTrack;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const List<Shadow> shadows = [
      Shadow(color: Colors.black54, blurRadius: 4),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showTrack)
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
    required this.tickLength,
    required this.strokeWidth,
    required this.color,
  });

  final Offset tapPosition;
  final double rectSize;
  final double tickLength;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double left = tapPosition.dx - rectSize / 2;
    final double top = tapPosition.dy - rectSize / 2;
    final double right = left + rectSize;
    final double bottom = top + rectSize;
    final double cx = tapPosition.dx;
    final double cy = tapPosition.dy;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);

    // Inward ticks centered on each side.
    canvas.drawLine(Offset(cx, top), Offset(cx, top + tickLength), paint);
    canvas.drawLine(Offset(cx, bottom), Offset(cx, bottom - tickLength), paint);
    canvas.drawLine(Offset(left, cy), Offset(left + tickLength, cy), paint);
    canvas.drawLine(Offset(right, cy), Offset(right - tickLength, cy), paint);
  }

  @override
  bool shouldRepaint(covariant _CameraFocusPainter oldDelegate) {
    return tapPosition != oldDelegate.tapPosition ||
        rectSize != oldDelegate.rectSize;
  }
}
