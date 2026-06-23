import 'dart:math' as math;
import 'dart:ui';

import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Curved zoom dial modeled after the iOS Camera app.
///
/// [minZoom] to [maxZoom] map to the ruler arc. Drag horizontally to adjust
/// zoom; [onChange] is called with the updated value.
class IosCameraZoomDial extends StatefulWidget {
  const IosCameraZoomDial({
    super.key,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onChange,
    this.showBlur = true,
    this.height = 132,
  })  : assert(minZoom > 0, 'minZoom must be positive for log-scale ruler'),
        assert(maxZoom >= minZoom, 'maxZoom must be >= minZoom');

  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onChange;
  final bool showBlur;
  final double height;

  @override
  State<IosCameraZoomDial> createState() => _IosCameraZoomDialState();
}

class _IosCameraZoomDialState extends State<IosCameraZoomDial> {
  static const double _dragSensitivity = 0.0045;
  static const double _labelProximity = 0.07;

  double? _dragZoom;
  int? _activePointer;

  List<double> get _majorStops =>
      _ZoomDialMetrics.majorStopsForRange(widget.minZoom, widget.maxZoom);

  double get _clampedZoom =>
      widget.currentZoom.clamp(widget.minZoom, widget.maxZoom);

  void _onHorizontalDrag(double deltaX) {
    final double previousZoom = _dragZoom ?? _clampedZoom;
    final double currentLog = math.log(previousZoom);
    final double nextLog = (currentLog - deltaX * _dragSensitivity).clamp(
      math.log(widget.minZoom),
      math.log(widget.maxZoom),
    );
    final double nextZoom = math.exp(nextLog);
    if ((nextZoom - previousZoom).abs() < 1e-9) return;

    _dragZoom = nextZoom;
    widget.onChange(nextZoom);
    _triggerMajorStopHaptics(from: previousZoom, to: nextZoom);
  }

  void _triggerMajorStopHaptics({
    required double from,
    required double to,
  }) {
    final double lower = math.min(from, to);
    final double upper = math.max(from, to);

    for (final double stop in _majorStops) {
      if (stop <= lower || stop >= upper) continue;
      HapticFeedback.selectionClick();
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (widget.maxZoom <= widget.minZoom) return;
    _activePointer = event.pointer;
    _dragZoom = _clampedZoom;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (widget.maxZoom <= widget.minZoom) return;
    if (_activePointer != event.pointer) return;
    _onHorizontalDrag(event.delta.dx);
  }

  void _onPointerEnd(PointerEvent event) {
    if (_activePointer != event.pointer) return;
    _activePointer = null;
    _dragZoom = null;
  }

  _ZoomDialLayout _layoutForWidth(double width) {
    final double radius = width * 0.72;
    final double bgRadius = radius + _ZoomDialMetrics.backgroundExtraRadius;
    final double arcCenterY = widget.height + radius * 0.42;
    final double topInset = math.max(
      0,
      bgRadius -
          arcCenterY +
          _ZoomDialMetrics.caretHeight +
          _ZoomDialMetrics.caretLift,
    );

    return _ZoomDialLayout(
      width: width,
      dialHeight: widget.height + topInset,
      radius: radius,
      bgRadius: bgRadius,
      arcCenter: Offset(width / 2, arcCenterY + topInset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _ZoomDialLayout layout = _layoutForWidth(constraints.maxWidth);
        final bool canDrag = widget.maxZoom > widget.minZoom;

        return SizedBox(
          height: layout.dialHeight,
          width: layout.width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.showBlur)
                Positioned(
                  left: layout.arcCenter.dx - layout.bgRadius,
                  top: layout.arcCenter.dy - layout.bgRadius,
                  width: layout.bgRadius * 2,
                  height: layout.bgRadius * 2,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        color: AppColors.colorBlackOpacity60,
                      ),
                    ),
                  ),
                ),
              CustomPaint(
                size: Size(layout.width, layout.dialHeight),
                painter: _ZoomDialTicksPainter(
                  zoom: _clampedZoom,
                  minZoom: widget.minZoom,
                  maxZoom: widget.maxZoom,
                  majorStops: _majorStops,
                  arcCenter: layout.arcCenter,
                  radius: layout.radius,
                  labelProximity: _labelProximity,
                ),
              ),
              if (canDrag)
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerEnd,
                    onPointerCancel: _onPointerEnd,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ZoomDialLayout {
  const _ZoomDialLayout({
    required this.width,
    required this.dialHeight,
    required this.radius,
    required this.bgRadius,
    required this.arcCenter,
  });

  final double width;
  final double dialHeight;
  final double radius;
  final double bgRadius;
  final Offset arcCenter;
}

class _ZoomDialMetrics {
  _ZoomDialMetrics._();

  static const double caretWidth = 9;
  static const double caretHeight = 18;
  static const double caretLift = 4;
  static const double bgTopPadding = 12;
  static const double backgroundExtraRadius =
      caretLift + caretHeight + bgTopPadding;

  static const List<double> _presetMajorStops = [
    0.5,
    1.0,
    2.0,
    3.0,
    5.0,
    10.0,
    15.0,
  ];

  /// Major ruler labels within [minZoom, maxZoom].
  static List<double> majorStopsForRange(double minZoom, double maxZoom) {
    final List<double> stops = _presetMajorStops
        .where((double stop) => stop >= minZoom - 0.001 && stop <= maxZoom + 0.001)
        .toList();

    if (stops.isNotEmpty) return stops;

    if (minZoom == maxZoom) return [minZoom];

    return [minZoom, maxZoom];
  }
}

class _IosZoomDialFormat {
  static String zoom(double value, {required bool withSuffix}) {
    final bool isWhole = (value - value.round()).abs() < 0.05;
    final String core = isWhole
        ? '${value.round()}'
        : value.toStringAsFixed(1).replaceAll('.', ',');
    return withSuffix ? '${core}x' : core;
  }
}

class _ZoomDialTicksPainter extends CustomPainter {
  const _ZoomDialTicksPainter({
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.majorStops,
    required this.arcCenter,
    required this.radius,
    required this.labelProximity,
  });

  final double zoom;
  final double minZoom;
  final double maxZoom;
  final List<double> majorStops;
  final Offset arcCenter;
  final double radius;
  final double labelProximity;

  static const double _visibleHalfAngle = 0.95;
  static const double _anglePerLogUnit = 0.72;
  static const double _labelFadeStartAngle = 0.22;
  static const double _labelFadeEndAngle = 0.08;

  @override
  void paint(Canvas canvas, Size size) {
    final double logZoom = math.log(zoom);
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    _paintMinorTicks(canvas, logZoom);
    _paintMajorTicks(canvas, logZoom);
    _paintActiveCenterTick(canvas);
    _paintWheelLabels(canvas, logZoom, textPainter);
    _paintCaret(canvas);
  }

  void _paintActiveCenterTick(Canvas canvas) {
    final Paint activeTickPaint = Paint()
      ..color = AppColors.color255_214_10
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    _drawRadialTick(
      canvas,
      angle: 0,
      innerRadius: radius - 16,
      outerRadius: radius,
      paint: activeTickPaint,
    );
  }

  void _paintCaret(Canvas canvas) {
    final Offset apex = _pointOnArc(0, radius);
    final double baseY =
        apex.dy - _ZoomDialMetrics.caretLift - _ZoomDialMetrics.caretHeight;

    final Path triangle = Path()
      ..moveTo(apex.dx, apex.dy - _ZoomDialMetrics.caretLift)
      ..lineTo(apex.dx - _ZoomDialMetrics.caretWidth / 2, baseY)
      ..lineTo(apex.dx + _ZoomDialMetrics.caretWidth / 2, baseY)
      ..close();

    canvas.drawPath(
      triangle,
      Paint()
        ..color = AppColors.color255_214_10
        ..style = PaintingStyle.fill,
    );
  }

  void _paintMinorTicks(Canvas canvas, double logZoom) {
    final double minLog = math.log(minZoom);
    final double maxLog = math.log(maxZoom);
    const int tickCount = 100;
    final double step = (maxLog - minLog) / tickCount;

    final Paint minorPaint = Paint()
      ..color = AppColors.white24
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= tickCount; i++) {
      final double tickZoom = math.exp(minLog + step * i);
      if (_isNearAnyMajorStop(tickZoom)) continue;

      final double angle = _angleForZoom(tickZoom, logZoom);
      if (angle.abs() > _visibleHalfAngle) continue;
      if (angle.abs() < 0.03) continue;

      _drawRadialTick(
        canvas,
        angle: angle,
        innerRadius: radius - 10,
        outerRadius: radius - 2,
        paint: minorPaint,
      );
    }
  }

  void _paintMajorTicks(Canvas canvas, double logZoom) {
    final Paint majorPaint = Paint()
      ..color = AppColors.white70
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (final double stop in majorStops) {
      if (stop < minZoom - 0.01 || stop > maxZoom + 0.01) continue;

      final double angle = _angleForZoom(stop, logZoom);
      if (angle.abs() > _visibleHalfAngle) continue;
      if (angle.abs() < 0.03) continue;

      _drawRadialTick(
        canvas,
        angle: angle,
        innerRadius: radius - 16,
        outerRadius: radius,
        paint: majorPaint,
      );
    }
  }

  void _paintWheelLabels(Canvas canvas, double logZoom, TextPainter textPainter) {
    final double? centeredStop = _centeredMajorStop();

    for (final double stop in majorStops) {
      if (stop < minZoom - 0.01 || stop > maxZoom + 0.01) continue;

      final double angle = _angleForZoom(stop, logZoom);
      if (angle.abs() > _visibleHalfAngle - 0.05) continue;
      if (centeredStop != null && (stop - centeredStop).abs() < 0.001) continue;

      final double opacity = _labelOpacityForAngle(angle);
      if (opacity <= 0) continue;

      _paintLabelOnWheel(
        canvas,
        textPainter: textPainter,
        angle: angle,
        zoomText: _IosZoomDialFormat.zoom(stop, withSuffix: false),
        isActive: false,
        opacity: opacity,
      );
    }

    _paintLabelOnWheel(
      canvas,
      textPainter: textPainter,
      angle: 0,
      zoomText: _IosZoomDialFormat.zoom(
        centeredStop ?? zoom,
        withSuffix: true,
      ),
      isActive: true,
      opacity: 1,
    );
  }

  double _labelOpacityForAngle(double angle) {
    final double absAngle = angle.abs();
    if (absAngle <= _labelFadeEndAngle) return 0;
    if (absAngle >= _labelFadeStartAngle) return 1;
    return (absAngle - _labelFadeEndAngle) /
        (_labelFadeStartAngle - _labelFadeEndAngle);
  }

  double? _centeredMajorStop() {
    for (final double stop in majorStops) {
      if ((stop - zoom).abs() < labelProximity) return stop;
    }
    return null;
  }

  void _paintLabelOnWheel(
    Canvas canvas, {
    required TextPainter textPainter,
    required double angle,
    required String zoomText,
    required bool isActive,
    required double opacity,
  }) {
    final Offset labelAnchor = _pointOnArc(angle, radius - 26);

    final Color baseColor =
        isActive ? AppColors.color255_214_10 : AppColors.white;
    final Color zoomColor = baseColor.withValues(alpha: baseColor.a * opacity);
    final double zoomFontSize = isActive ? 15 : 13;

    textPainter.text = TextSpan(
      text: zoomText,
      style: TextStyle(
        color: zoomColor,
        fontSize: zoomFontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.1,
      ),
    );
    textPainter.layout();

    final Offset zoomOffset = _labelOffsetFromTick(
      labelAnchor: labelAnchor,
      textWidth: textPainter.width,
      textHeight: textPainter.height,
      gap: 6,
    );
    textPainter.paint(canvas, zoomOffset);
  }

  Offset _labelOffsetFromTick({
    required Offset labelAnchor,
    required double textWidth,
    required double textHeight,
    required double gap,
  }) {
    final Offset inward = (arcCenter - labelAnchor);
    final Offset inwardUnit = inward / inward.distance;

    return Offset(
      labelAnchor.dx - textWidth / 2 + inwardUnit.dx * 0,
      labelAnchor.dy - textHeight / 2 + inwardUnit.dy * gap,
    );
  }

  void _drawRadialTick(
    Canvas canvas, {
    required double angle,
    required double innerRadius,
    required double outerRadius,
    required Paint paint,
  }) {
    final Offset inner = _pointOnArc(angle, innerRadius);
    final Offset outer = _pointOnArc(angle, outerRadius);
    canvas.drawLine(inner, outer, paint);
  }

  Offset _pointOnArc(double angle, double arcRadius) {
    final double theta = math.pi / 2 + angle;
    return Offset(
      arcCenter.dx + math.cos(theta) * arcRadius,
      arcCenter.dy - math.sin(theta) * arcRadius,
    );
  }

  /// Lower zoom sits on the left, higher zoom on the right (iOS layout).
  double _angleForZoom(double tickZoom, double logZoom) {
    return (logZoom - math.log(tickZoom)) * _anglePerLogUnit;
  }

  bool _isNearAnyMajorStop(double value) {
    return majorStops.any((stop) => (stop - value).abs() < 0.04);
  }

  @override
  bool shouldRepaint(covariant _ZoomDialTicksPainter oldDelegate) {
    return oldDelegate.zoom != zoom ||
        oldDelegate.minZoom != minZoom ||
        oldDelegate.maxZoom != maxZoom ||
        oldDelegate.majorStops != majorStops ||
        oldDelegate.arcCenter != arcCenter ||
        oldDelegate.radius != radius;
  }
}
