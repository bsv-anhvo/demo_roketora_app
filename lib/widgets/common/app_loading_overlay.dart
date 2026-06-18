import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Full-screen blocking loader. Place inside a [Stack] to cover its bounds.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor = AppColors.colorBlackOpacity60,
  });

  final String? message;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: backgroundColor,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.white),
                if (message != null) ...[
                  const Gap(16),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
