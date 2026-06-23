import 'package:demo_roketota_app/core/extensions/logger_extension.dart';
import 'package:demo_roketota_app/core/models/zoom_range.dart';
import 'package:demo_roketota_app/utils/camera_helper.dart';
import 'package:demo_roketota_app/widgets/camera/ios_camera_zoom_dial.dart';
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IosCameraZoomDial(
        currentZoom: displayZoom,
        minZoom: stops.first,
        maxZoom: stops.last,
        onChange: (stop) {
          "zoom level: $stop".log();
          onZoomSelected(stop);
        },
      ),
    );
  }
}
