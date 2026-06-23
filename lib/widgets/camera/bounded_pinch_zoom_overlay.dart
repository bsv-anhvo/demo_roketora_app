import 'package:demo_roketota_app/core/models/zoom_range.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Smooth pinch-to-zoom over the camera preview using [ScaleUpdateDetails.scale].
/// Only handles scale so tap-to-focus on the preview still works underneath.
class BoundedPinchZoomOverlay extends StatefulWidget {
  const BoundedPinchZoomOverlay({
    super.key,
    required this.range,
    required this.displayZoom,
    required this.onDisplayZoom,
  });

  final ZoomRange range;
  final double displayZoom;
  final ValueChanged<double> onDisplayZoom;

  @override
  State<BoundedPinchZoomOverlay> createState() =>
      _BoundedPinchZoomOverlayState();
}

class _BoundedPinchZoomOverlayState extends State<BoundedPinchZoomOverlay> {
  double? _startDisplayZoom;
  double? _lastAppliedDisplayZoom;

  static const double _minDisplayStep = 0.005;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        ScaleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
          () => ScaleGestureRecognizer(),
          (ScaleGestureRecognizer instance) {
            instance
              ..onStart = _onScaleStart
              ..onUpdate = _onScaleUpdate
              ..onEnd = _onScaleEnd;
          },
        ),
      },
      child: const SizedBox.expand(),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startDisplayZoom = widget.range.clampDisplayZoom(widget.displayZoom);
    _lastAppliedDisplayZoom = _startDisplayZoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final double? start = _startDisplayZoom;
    if (start == null) return;

    final double target =
        widget.range.clampDisplayZoom(start * details.scale);
    if (_lastAppliedDisplayZoom != null &&
        (target - _lastAppliedDisplayZoom!).abs() < _minDisplayStep) {
      return;
    }

    _lastAppliedDisplayZoom = target;
    widget.onDisplayZoom(target);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _startDisplayZoom = null;
    _lastAppliedDisplayZoom = null;
  }
}
