import 'package:demo_roketota_app/core/extensions/context_extension.dart';
import 'package:demo_roketota_app/screens/take_photo_screen.dart';
import 'package:demo_roketota_app/screens/video_record_screen.dart';
import 'package:demo_roketota_app/utils/device_requirements.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/widgets/common/app_action_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _locationReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLocationRequirements());
  }

  Future<void> _checkLocationRequirements() async {
    final LocationRequirementStatus status =
        await DeviceRequirements.ensureLocation();

    if (!mounted) return;

    setState(() => _locationReady = status == LocationRequirementStatus.ready);

    if (status != LocationRequirementStatus.ready) {
      await DeviceRequirements.showLocationIssue(context, status);
    }
  }

  void _openTakePhoto(BuildContext context) {
    context.push(const TakePhotoScreen());
  }

  void _openVideoRecord(BuildContext context) {
    context.push(const VideoRecordScreen());
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.camera_alt_rounded,
                size: 72,
                color: colorScheme.primary,
              ),
              const Gap(16),
              Text(
                Strings.labelApp,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (!_locationReady) ...[
                const Gap(16),
                _buildMsgLocationPermissionOrGPSIsNotReadyWidget(
                  colorScheme: colorScheme,
                  onTapEvent: _checkLocationRequirements,
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: AppActionButton(
                      icon: Icons.photo_camera_rounded,
                      label: Strings.labelTakePhoto,
                      color: colorScheme.primary,
                      onPressed: () => _openTakePhoto(context),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: AppActionButton(
                      icon: Icons.videocam_rounded,
                      label: Strings.labelRecordVideo,
                      color: colorScheme.secondary,
                      onPressed: () => _openVideoRecord(context),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildMsgLocationPermissionOrGPSIsNotReadyWidget({
  required ColorScheme colorScheme,
  required VoidCallback onTapEvent,
}) {
  const borderRadius = BorderRadius.all(Radius.circular(12));

  return Material(
    color: colorScheme.errorContainer,
    borderRadius: borderRadius,
    child: InkWell(
      onTap: onTapEvent,
      borderRadius: borderRadius,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.location_off_outlined,
              color: colorScheme.onErrorContainer,
            ),
            const Gap(12),
            Expanded(
              child: Text(
                Strings.msgLocationPermissionOrGPSIsNotReady,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
