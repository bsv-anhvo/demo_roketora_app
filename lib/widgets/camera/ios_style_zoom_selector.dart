import 'dart:async';

import 'package:demo_roketota_app/core/models/zoom_range.dart';
import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:demo_roketota_app/utils/camera_helper.dart';
import 'package:demo_roketota_app/widgets/camera/ios_camera_zoom_dial.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class IosStyleZoomSelector extends StatefulWidget {
  const IosStyleZoomSelector({
    super.key,
    required this.range,
    required this.displayZoom,
    required this.onZoomSelected,
  });

  final ZoomRange range;
  final double displayZoom;
  final ValueChanged<double> onZoomSelected;

  @override
  State<IosStyleZoomSelector> createState() => _IosStyleZoomSelectorState();
}

class _IosStyleZoomSelectorState extends State<IosStyleZoomSelector> {
  static const Duration _dialHideDelay = Duration(seconds: 1);
  static const double _stopSpacing = 2;
  static const double _barPadding = 4;
  static const double _selectedStopSize = 40;
  static const double _unselectedStopSize = 28;

  bool _showDial = false;
  Timer? _hideDialTimer;
  int? _trackingPointer;
  bool _hasMoved = false;
  int? _pressedStopIndex;
  Offset? _downGlobalPosition;

  @override
  void dispose() {
    _hideDialTimer?.cancel();
    super.dispose();
  }

  int? _stopIndexAt(Offset localPosition, List<double> stops, double activeStop) {
    double x = _barPadding;
    const double rowHeight = _selectedStopSize;

    for (int i = 0; i < stops.length; i++) {
      final bool selected = stops[i] == activeStop;
      final double size = selected ? _selectedStopSize : _unselectedStopSize;
      final double yOffset = _barPadding + (rowHeight - size) / 2;
      final Rect hitRect = Rect.fromLTWH(x, yOffset, size, size);

      if (hitRect.contains(localPosition)) {
        return i;
      }

      x += size;
      if (i < stops.length - 1) {
        x += _stopSpacing;
      }
    }

    return null;
  }

  void _onPointerDown(PointerDownEvent event) {
    _hideDialTimer?.cancel();
    if (!_showDial) {
      _trackingPointer = event.pointer;
      _hasMoved = false;
      _pressedStopIndex = null;
      _downGlobalPosition = event.position;

      final List<double> stops = CameraHelper.cameraZoomBuildStops(widget.range);
      final double activeStop = CameraHelper.cameraZoomClosestStop(
        widget.displayZoom,
        stops,
      );
      _pressedStopIndex = _stopIndexAt(event.localPosition, stops, activeStop);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_showDial || _trackingPointer != event.pointer || _hasMoved) return;

    final Offset? downPosition = _downGlobalPosition;
    if (downPosition == null) return;
    if ((event.position - downPosition).distance < kTouchSlop) return;

    _hasMoved = true;
    _pressedStopIndex = null;
    setState(() => _showDial = true);
  }

  void _onPointerUp(PointerEvent event) {
    if (_trackingPointer == event.pointer) {
      if (!_hasMoved && !_showDial && _pressedStopIndex != null) {
        final List<double> stops =
            CameraHelper.cameraZoomBuildStops(widget.range);
        widget.onZoomSelected(stops[_pressedStopIndex!]);
      }
      _trackingPointer = null;
      _pressedStopIndex = null;
      _downGlobalPosition = null;
    }
    if (_showDial) {
      _scheduleHideDial();
    }
  }

  void _scheduleHideDial() {
    _hideDialTimer?.cancel();
    _hideDialTimer = Timer(_dialHideDelay, () {
      if (!mounted) return;
      setState(() {
        _showDial = false;
        _hasMoved = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<double> stops = CameraHelper.cameraZoomBuildStops(widget.range);
    final double activeStop =
        CameraHelper.cameraZoomClosestStop(widget.displayZoom, stops);

    return Center(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: _showDial
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IosCameraZoomDial(
                  currentZoom: widget.displayZoom,
                  minZoom: stops.first,
                  maxZoom: stops.last,
                  onChange: widget.onZoomSelected,
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.colorBlackOpacity40,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final double stop in stops) ...[
                      _IosZoomStop(
                        label: CameraHelper.formatZoomLabel(
                          stop,
                          stop == activeStop ? widget.displayZoom : stop,
                          compact: stop != activeStop,
                        ),
                        isSelected: stop == activeStop,
                      ),
                      if (stop != stops.last) const SizedBox(width: 2),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _IosZoomStop extends StatelessWidget {
  const _IosZoomStop({
    required this.label,
    required this.isSelected,
  });

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: isSelected ? 40 : 28,
      height: isSelected ? 40 : 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.color58_58_60_op70 : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 180),
        style: TextStyle(
          color: isSelected ? AppColors.color255_214_10 : AppColors.white70,
          fontSize: isSelected ? 13 : 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          letterSpacing: -0.2,
        ),
        child: Text(label),
      ),
    );
  }
}
