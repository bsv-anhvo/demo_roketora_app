import 'package:demo_roketota_app/screens/camera_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCamera(BuildContext context, CameraDemoMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CameraScreen(mode: mode),
      ),
    );
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
              const SizedBox(height: 16),
              Text(
                'Roketota Camera Demo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn chức năng camera để demo cho khách hàng',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              _DemoActionButton(
                icon: Icons.photo_camera_rounded,
                label: 'Take Photo',
                subtitle: 'Chụp ảnh với camera sau',
                color: colorScheme.primary,
                onPressed: () => _openCamera(context, CameraDemoMode.photo),
              ),
              const SizedBox(height: 16),
              _DemoActionButton(
                icon: Icons.videocam_rounded,
                label: 'Video Record',
                subtitle: 'Quay video có âm thanh',
                color: colorScheme.secondary,
                onPressed: () => _openCamera(context, CameraDemoMode.video),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoActionButton extends StatelessWidget {
  const _DemoActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        ],
      ),
    );
  }
}
