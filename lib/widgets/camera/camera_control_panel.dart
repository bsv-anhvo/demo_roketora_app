import 'package:demo_roketota_app/models/camera_settings.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:flutter/material.dart';

typedef SettingTapCallback<T> = void Function(T value);

class CameraControlPanel extends StatelessWidget {
  const CameraControlPanel({
    super.key,
    required this.isPhotoMode,
    required this.flash,
    required this.timer,
    required this.portraitEnabled,
    required this.exposure,
    required this.onFlashTap,
    required this.onTimerTap,
    required this.onPortraitTap,
    required this.onExposureChanged,
    required this.onResolutionTap,
    this.resolutionLabel,
    this.onFpsTap,
    this.fpsLabel,
    this.showExposureSlider = false,
    this.showFilterStrip = false,
    this.onToggleExposure,
    this.onToggleFilter,
  });

  final bool isPhotoMode;
  final FlashSetting flash;
  final PhotoTimerOption timer;
  final bool portraitEnabled;
  final double exposure;
  final String? resolutionLabel;
  final String? fpsLabel;
  final bool showExposureSlider;
  final bool showFilterStrip;
  final VoidCallback onFlashTap;
  final VoidCallback onTimerTap;
  final VoidCallback onPortraitTap;
  final VoidCallback? onToggleExposure;
  final VoidCallback? onToggleFilter;
  final ValueChanged<double> onExposureChanged;
  final VoidCallback onResolutionTap;
  final VoidCallback? onFpsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showExposureSlider) ...[
          _ExposureSlider(
            value: exposure,
            onChanged: onExposureChanged,
          ),
          const SizedBox(height: 8),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ControlChip(
                icon: _flashIcon(flash),
                label: flash.label,
                onTap: onFlashTap,
              ),
              _ControlChip(
                icon: Icons.brightness_6_outlined,
                label: Strings.labelExposure,
                isActive: showExposureSlider,
                onTap: onToggleExposure ?? () {},
              ),
              _ControlChip(
                icon: Icons.auto_awesome_outlined,
                label: Strings.labelFilter,
                isActive: showFilterStrip,
                onTap: onToggleFilter ?? () {},
              ),
              if (isPhotoMode) ...[
                _ControlChip(
                  icon: Icons.timer_outlined,
                  label: timer.label,
                  onTap: onTimerTap,
                ),
                // _ControlChip(
                //   icon: Icons.face_retouching_natural_outlined,
                //   label: Strings.labelPortrait,
                //   isActive: portraitEnabled,
                //   onTap: onPortraitTap,
                // ),
              ],
              _ControlChip(
                icon: Icons.hd_outlined,
                label: resolutionLabel ?? Strings.labelResolution,
                onTap: onResolutionTap,
              ),
              if (!isPhotoMode && onFpsTap != null)
                _ControlChip(
                  icon: Icons.speed_outlined,
                  label: fpsLabel ?? Strings.labelFps,
                  onTap: onFpsTap!,
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _flashIcon(FlashSetting setting) => switch (setting) {
        FlashSetting.off => Icons.flash_off,
        FlashSetting.on => Icons.flash_on,
        FlashSetting.auto => Icons.flash_auto,
      };
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isActive ? Colors.white24 : Colors.black45,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExposureSlider extends StatelessWidget {
  const _ExposureSlider({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.exposure, color: Colors.white, size: 18),
          Expanded(
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              activeColor: Colors.amber,
              onChanged: onChanged,
            ),
          ),
          Text(
            _formatExposureOffset(value),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _formatExposureOffset(double value) {
  final int offset = ((value - 0.5) * 200).round();
  if (offset == 0) return '0';
  return offset > 0 ? '+$offset' : '$offset';
}

Future<T?> showCameraPickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T option) labelBuilder,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final double maxSheetHeight = MediaQuery.sizeOf(context).height * 0.65;

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: Colors.white12,
                  ),
                  itemBuilder: (context, index) {
                    final T option = options[index];
                    final bool isSelected = option == selected;

                    return ListTile(
                      dense: true,
                      title: Text(
                        labelBuilder(option),
                        style: TextStyle(
                          color: isSelected ? Colors.amber : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.amber)
                          : null,
                      onTap: () => Navigator.pop(context, option),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
