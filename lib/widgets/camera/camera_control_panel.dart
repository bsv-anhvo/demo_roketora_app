import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

typedef SettingTapCallback<T> = void Function(T value);

class CameraControlPanel extends StatelessWidget {
  const CameraControlPanel({
    super.key,
    required this.isPhotoMode,
    required this.flash,
    required this.timer,
    required this.onFlashTap,
    required this.onTimerTap,
    required this.onExposureChanged,
    required this.onResolutionTap,
    this.resolutionLabel,
    this.onFpsTap,
    this.fpsLabel,
    this.resolutionIcon,
    this.showFilterStrip = false,
    this.onToggleFilter,
  });

  final bool isPhotoMode;
  final FlashSetting flash;
  final PhotoTimerOption timer;
  final String? resolutionLabel;
  final String? fpsLabel;
  final bool showFilterStrip;
  final VoidCallback onFlashTap;
  final VoidCallback onTimerTap;
  final VoidCallback? onToggleFilter;
  final ValueChanged<double> onExposureChanged;
  final VoidCallback onResolutionTap;
  final VoidCallback? onFpsTap;
  final IconData? resolutionIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              ],
              _ControlChip(
                icon: resolutionIcon ??
                    (isPhotoMode ? Icons.aspect_ratio : Icons.hd_outlined),
                label: resolutionLabel ??
                    (isPhotoMode ? Strings.labelAspectRatio : Strings.labelResolution),
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
        color: isActive ? AppColors.white24 : AppColors.black45,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.white, size: 18),
                const Gap(6),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
    backgroundColor: AppColors.color30_30_30,
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
              const Gap(8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
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
                    color: AppColors.white12,
                  ),
                  itemBuilder: (context, index) {
                    final T option = options[index];
                    final bool isSelected = option == selected;

                    return ListTile(
                      dense: true,
                      title: Text(
                        labelBuilder(option),
                        style: TextStyle(
                          color: isSelected ? AppColors.amber : AppColors.white,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.amber)
                          : null,
                      onTap: () => Navigator.pop(context, option),
                    );
                  },
                ),
              ),
              const Gap(8),
            ],
          ),
        ),
      );
    },
  );
}
