import 'package:demo_roketota_app/core/models/zoom_range.dart';
import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:demo_roketota_app/utils/camera_helper.dart';
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
    final List<double> stops = CameraHelper.cameraZoomBuildStops(range);
    final double activeStop = CameraHelper.cameraZoomClosestStop(displayZoom, stops);

    return Center(
      child: Container(
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
          color: isSelected ? AppColors.color58_58_60_opacity_70 : Colors.transparent,
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
      ),
    );
  }
}
