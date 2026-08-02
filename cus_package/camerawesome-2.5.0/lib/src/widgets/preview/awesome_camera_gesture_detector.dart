import 'dart:async';

import 'package:camerawesome/pigeon.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:camerawesome/src/widgets/preview/awesome_focus_indicator.dart';

Widget _awesomeFocusBuilder(Offset tapPosition) {
  return AwesomeFocusIndicator(position: tapPosition);
}

class OnPreviewTapBuilder {
  // Use getters instead of storing the direct value to retrieve the data onTap
  final PreviewSize Function() pixelPreviewSizeGetter;
  final PreviewSize Function() flutterPreviewSizeGetter;
  final OnPreviewTap onPreviewTap;

  const OnPreviewTapBuilder({
    required this.pixelPreviewSizeGetter,
    required this.flutterPreviewSizeGetter,
    required this.onPreviewTap,
  });
}

class OnPreviewTap {
  final Function(Offset position, PreviewSize flutterPreviewSize,
      PreviewSize pixelPreviewSize) onTap;
  final Widget Function(Offset tapPosition)? onTapPainter;
  final Duration? tapPainterDuration;

  const OnPreviewTap({
    required this.onTap,
    this.onTapPainter = _awesomeFocusBuilder,
    this.tapPainterDuration = const Duration(milliseconds: 2000),
  });
}

class OnPreviewScale {
  /// Legacy absolute zoom in [0, 1]. Ignored when [onPinchUpdate] is set.
  final Function(double scale) onScale;

  /// Called once when a pinch/scale gesture begins.
  final VoidCallback? onPinchStart;

  /// Multiplicative pinch factor from [ScaleUpdateDetails.scale] (starts at 1.0).
  final void Function(double scaleFactor)? onPinchUpdate;

  /// Called when the pinch/scale gesture ends.
  final VoidCallback? onPinchEnd;

  const OnPreviewScale({
    required this.onScale,
    this.onPinchStart,
    this.onPinchUpdate,
    this.onPinchEnd,
  });

  bool get usePinchCallbacks => onPinchUpdate != null;
}

class AwesomeCameraGestureDetector extends StatefulWidget {
  final Widget child;
  final OnPreviewTapBuilder? onPreviewTapBuilder;
  final OnPreviewScale? onPreviewScale;
  final double initialZoom;

  const AwesomeCameraGestureDetector({
    super.key,
    required this.child,
    required this.onPreviewScale,
    this.onPreviewTapBuilder,
    this.initialZoom = 0,
  });

  @override
  State<StatefulWidget> createState() {
    return _AwesomeCameraGestureDetector();
  }
}

class _AwesomeCameraGestureDetector
    extends State<AwesomeCameraGestureDetector> {
  double _zoomScale = 0;
  final double _accuracy = 0.01;
  double? _lastScale;

  Offset? _tapPosition;
  Timer? _timer;

  /// Listener-based tap tracking so ScaleGestureRecognizer cannot steal taps.
  int? _tapPointer;
  Offset? _tapDownPosition;
  bool _tapMovedBeyondSlop = false;
  int _activePointers = 0;

  @override
  void initState() {
    _zoomScale = widget.initialZoom;
    super.initState();
  }

  void _handleTapUp(Offset localPosition) {
    if (widget.onPreviewTapBuilder == null) return;

    if (widget.onPreviewTapBuilder!.onPreviewTap.tapPainterDuration != null) {
      _timer?.cancel();
      _timer = Timer(
          widget.onPreviewTapBuilder!.onPreviewTap.tapPainterDuration!, () {
        if (!mounted) return;
        setState(() {
          _tapPosition = null;
        });
      });
    }
    setState(() {
      _tapPosition = localPosition;
    });
    widget.onPreviewTapBuilder!.onPreviewTap.onTap(
      localPosition,
      widget.onPreviewTapBuilder!.flutterPreviewSizeGetter(),
      widget.onPreviewTapBuilder!.pixelPreviewSizeGetter(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (PointerDownEvent event) {
        _activePointers++;
        if (_activePointers == 1) {
          _tapPointer = event.pointer;
          _tapDownPosition = event.localPosition;
          _tapMovedBeyondSlop = false;
        } else {
          // Multi-touch: cancel pending tap.
          _tapPointer = null;
          _tapDownPosition = null;
        }
      },
      onPointerMove: (PointerMoveEvent event) {
        if (_tapPointer != event.pointer || _tapDownPosition == null) return;
        if ((event.localPosition - _tapDownPosition!).distance >
            kTouchSlop) {
          _tapMovedBeyondSlop = true;
        }
      },
      onPointerUp: (PointerUpEvent event) {
        _activePointers = (_activePointers - 1).clamp(0, 100);
        if (_tapPointer == event.pointer &&
            _tapDownPosition != null &&
            !_tapMovedBeyondSlop &&
            _activePointers == 0) {
          _handleTapUp(event.localPosition);
        }
        if (_tapPointer == event.pointer) {
          _tapPointer = null;
          _tapDownPosition = null;
        }
      },
      onPointerCancel: (PointerCancelEvent event) {
        _activePointers = (_activePointers - 1).clamp(0, 100);
        if (_tapPointer == event.pointer) {
          _tapPointer = null;
          _tapDownPosition = null;
        }
      },
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          if (widget.onPreviewScale != null)
            ScaleGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
              () => ScaleGestureRecognizer()
                ..onStart = (_) {
                  _lastScale = null;
                  widget.onPreviewScale!.onPinchStart?.call();
                }
                ..onUpdate = (ScaleUpdateDetails details) {
                  final OnPreviewScale previewScale = widget.onPreviewScale!;
                  // Only apply pinch when two fingers are involved.
                  if (details.pointerCount < 2) return;

                  if (previewScale.usePinchCallbacks) {
                    previewScale.onPinchUpdate!(details.scale);
                    return;
                  }

                  _lastScale ??= details.scale;
                  if (details.scale < (_lastScale! + 0.01) &&
                      details.scale > (_lastScale! - 0.01)) {
                    return;
                  } else if (_lastScale! < details.scale) {
                    _zoomScale += _accuracy;
                  } else {
                    _zoomScale -= _accuracy;
                  }

                  _zoomScale = _zoomScale.clamp(0, 1);
                  previewScale.onScale(_zoomScale);
                  _lastScale = details.scale;
                }
                ..onEnd = (_) {
                  widget.onPreviewScale!.onPinchEnd?.call();
                },
              (instance) {},
            ),
        },
        child: Stack(children: [
          Positioned.fill(child: widget.child),
          if (_tapPosition != null &&
              widget.onPreviewTapBuilder?.onPreviewTap.onTapPainter != null)
            widget.onPreviewTapBuilder!.onPreviewTap
                .onTapPainter!(_tapPosition!),
        ]),
      ),
    );
  }

  @override
  dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
