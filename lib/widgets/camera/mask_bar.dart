import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class MaskBar extends StatelessWidget {
  const MaskBar({
    super.key,
    this.top,
    this.bottom,
    required this.height,
  });

  final double? top;
  final double? bottom;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: 0,
      right: 0,
      height: height,
      child: const IgnorePointer(
        child: ColoredBox(color: AppColors.black),
      ),
    );
  }
}