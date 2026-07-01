import 'dart:ui';

import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Horizontal exposure bar for photo and video modes (iOS Camera style).
///
/// [exposure] is normalized in [0, 1]; 0.5 is neutral (0 EV). Drag the scale
/// horizontally to adjust brightness; [onClose] dismisses the bar.
class CameraExposure extends StatefulWidget {
  /// Fixed bar height; use with bottom slot padding to reserve layout space.
  static const double preferredHeight = 52;

  const CameraExposure({
    super.key,
    required this.exposure,
    required this.onExposureChanged,
    required this.onClose,
    this.minEv = -2.0,
    this.maxEv = 2.0,
    this.stepEv = 0.3,
  });

  /// Normalized exposure in [0, 1]; 0.5 is neutral.
  final double exposure;

  final ValueChanged<double> onExposureChanged;
  final VoidCallback onClose;

  /// EV compensation range mapped to [0, 1].
  final double minEv;
  final double maxEv;

  /// Spacing between minor tick marks on the ruler.
  final double stepEv;

  @override
  State<CameraExposure> createState() => _CameraExposureState();
}

class _CameraExposureState extends State<CameraExposure> {
  static const double _dragSensitivity = 0.0045;
  static const double _height = CameraExposure.preferredHeight;
  static const double _closeHitSize = 40;

  double? _dragExposure;
  int? _activePointer;
  double? _lastHapticEv;

  double get _clampedExposure => widget.exposure.clamp(0.0, 1.0);

  double _evFromExposure(double normalized) {
    return widget.minEv + normalized * (widget.maxEv - widget.minEv);
  }

  double _exposureFromEv(double ev) {
    final double range = widget.maxEv - widget.minEv;
    if (range <= 0) return 0.5;
    return ((ev - widget.minEv) / range).clamp(0.0, 1.0);
  }

  String _formatEv(double ev) {
    final double rounded = (ev * 10).round() / 10;
    final String text = rounded.toStringAsFixed(1);
    return text.replaceAll('.', ',');
  }

  void _onHorizontalDrag(double deltaX) {
    final double previous = _dragExposure ?? _clampedExposure;
    final double previousEv = _evFromExposure(previous);
    final double evRange = widget.maxEv - widget.minEv;
    final double nextEv =
        (previousEv + deltaX * _dragSensitivity * evRange).clamp(
      widget.minEv,
      widget.maxEv,
    );
    final double next = _exposureFromEv(nextEv);
    if ((next - previous).abs() < 1e-9) return;

    _dragExposure = next;
    widget.onExposureChanged(next);
    _triggerStepHaptics(nextEv);
  }

  void _triggerStepHaptics(double ev) {
    final double snapped = (ev / widget.stepEv).round() * widget.stepEv;
    if (_lastHapticEv != null && (_lastHapticEv! - snapped).abs() < 0.01) {
      return;
    }
    _lastHapticEv = snapped;
    HapticFeedback.selectionClick();
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointer = event.pointer;
    _dragExposure = _clampedExposure;
    _lastHapticEv = null;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer) return;
    _onHorizontalDrag(event.delta.dx);
  }

  void _onPointerEnd(PointerEvent event) {
    if (_activePointer != event.pointer) return;
    _activePointer = null;
    _dragExposure = null;
    _lastHapticEv = null;
  }

  @override
  Widget build(BuildContext context) {
    final double exposure = _clampedExposure;
    final double ev = _evFromExposure(exposure);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_height / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.color58_58_60_op70,
              borderRadius: BorderRadius.circular(_height / 2),
            ),
            child: SizedBox(
              height: _height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _onPointerDown,
                      onPointerMove: _onPointerMove,
                      onPointerUp: _onPointerEnd,
                      onPointerCancel: _onPointerEnd,
                      child: CustomPaint(
                        painter: _ExposureRulerPainter(
                          ev: ev,
                          minEv: widget.minEv,
                          maxEv: widget.maxEv,
                          stepEv: widget.stepEv,
                          label: _formatEv(ev),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    width: _closeHitSize,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onClose,
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExposureRulerPainter extends CustomPainter {
  const _ExposureRulerPainter({
    required this.ev,
    required this.minEv,
    required this.maxEv,
    required this.stepEv,
    required this.label,
  });

  final double ev;
  final double minEv;
  final double maxEv;
  final double stepEv;
  final String label;

  static const double _pixelsPerEv = 36;
  static const double _minorTickHeight = 10;
  static const double _centerTickHeight = 22;
  static const double _fadeStart = 72;
  static const double _fadeEnd = 120;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double baselineY = size.height * 0.62;

    _paintTicks(canvas, size, centerX, baselineY);
    _paintCenterIndicator(canvas, centerX, baselineY, size);
  }

  void _paintTicks(
    Canvas canvas,
    Size size,
    double centerX,
    double baselineY,
  ) {
    final Paint minorPaint = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final double firstTick =
        (minEv / stepEv).ceil() * stepEv;
    final double lastTick =
        (maxEv / stepEv).floor() * stepEv;

    for (double tickEv = firstTick;
        tickEv <= lastTick + 0.001;
        tickEv += stepEv) {
      if ((tickEv - ev).abs() < stepEv * 0.15) continue;

      final double offsetX = (tickEv - ev) * _pixelsPerEv;
      final double x = centerX + offsetX;
      if (x < 0 || x > size.width) continue;

      final double opacity = _opacityForOffset(offsetX.abs());
      if (opacity <= 0) continue;

      minorPaint.color = AppColors.white.withValues(alpha: 0.45 * opacity);
      canvas.drawLine(
        Offset(x, baselineY - _minorTickHeight / 2),
        Offset(x, baselineY + _minorTickHeight / 2),
        minorPaint,
      );
    }
  }

  void _paintCenterIndicator(
    Canvas canvas,
    double centerX,
    double baselineY,
    Size size,
  ) {
    final Paint centerPaint = Paint()
      ..color = AppColors.color255_214_10
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, baselineY - _centerTickHeight / 2),
      Offset(centerX, baselineY + _centerTickHeight / 2),
      centerPaint,
    );

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: AppColors.color255_214_10,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        baselineY - _centerTickHeight / 2 - textPainter.height - 4,
      ),
    );
  }

  double _opacityForOffset(double offset) {
    if (offset <= _fadeStart) return 1;
    if (offset >= _fadeEnd) return 0;
    return 1 - (offset - _fadeStart) / (_fadeEnd - _fadeStart);
  }

  @override
  bool shouldRepaint(covariant _ExposureRulerPainter oldDelegate) {
    return oldDelegate.ev != ev ||
        oldDelegate.minEv != minEv ||
        oldDelegate.maxEv != maxEv ||
        oldDelegate.stepEv != stepEv ||
        oldDelegate.label != label;
  }
}
