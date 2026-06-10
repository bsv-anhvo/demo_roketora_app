import 'package:demo_roketota_app/utils/camera_zoom_helper.dart';
import 'package:flutter/material.dart';

class IosStyleZoomSelector extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final List<double> stops = CameraZoomHelper.buildStops(range);
    final double activeStop = CameraZoomHelper.closestStop(displayZoom, stops);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final double stop in stops) ...[
              _IosZoomStop(
                label: CameraZoomHelper.formatZoomLabel(
                  stop,
                  compact: stop != activeStop,
                ),
                isSelected: stop == activeStop,
                onTap: () => onZoomSelected(stop),
              ),
              if (stop != stops.last) const SizedBox(width: 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _IosZoomStop extends StatelessWidget {
  const _IosZoomStop({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: isSelected ? 40 : 28,
        height: isSelected ? 40 : 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xB33A3A3C) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFD60A) : Colors.white70,
            fontSize: isSelected ? 13 : 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: -0.2,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
