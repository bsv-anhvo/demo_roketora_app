import 'package:flutter/material.dart';

class CameraSettingsToggleButton extends StatelessWidget {
  const CameraSettingsToggleButton({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        isActive ? Icons.tune_rounded : Icons.tune_outlined,
        color: isActive ? Colors.white : Colors.white70,
      ),
    );
  }
}
