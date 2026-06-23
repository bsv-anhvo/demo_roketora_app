import 'package:demo_roketota_app/core/extensions/context_extension.dart';
import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:demo_roketota_app/widgets/camera/ios_camera_zoom_dial.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Preview screen for [IosCameraZoomDial] with a camera-like layout.
class IosZoomDialDemoScreen extends StatefulWidget {
  const IosZoomDialDemoScreen({super.key});

  @override
  State<IosZoomDialDemoScreen> createState() => _IosZoomDialDemoScreenState();
}

class _IosZoomDialDemoScreenState extends State<IosZoomDialDemoScreen> {
  double _zoom = 1.0;

  static const List<double> _majorStops = [0.5, 1.0, 2.0, 3.0, 5.0, 15.0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _FakeCameraPreview(),
          SafeArea(
            child: Column(
              children: [
                _DemoTopBar(onBack: () => context.pop()),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IosCameraZoomDial(
                    zoom: _zoom,
                    minZoom: 0.5,
                    maxZoom: 15.0,
                    majorStops: _majorStops,
                    onZoomChanged: (double value) => setState(() => _zoom = value),
                  ),
                ),
                const Gap(12),
                const _DemoShutterButton(),
                const Gap(28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoTopBar extends StatelessWidget {
  const _DemoTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.white),
          ),
          const Expanded(
            child: Text(
              'iOS Zoom Dial',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _FakeCameraPreview extends StatelessWidget {
  const _FakeCameraPreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A2A2E),
            Color(0xFF121214),
            Color(0xFF080809),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _PreviewGridPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PreviewGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = AppColors.white24
      ..strokeWidth = 0.8;

    final double thirdW = size.width / 3;
    final double thirdH = size.height / 3;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(thirdW * i, 0), Offset(thirdW * i, size.height), gridPaint);
      canvas.drawLine(Offset(0, thirdH * i), Offset(size.width, thirdH * i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DemoShutterButton extends StatelessWidget {
  const _DemoShutterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white38, width: 3),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
