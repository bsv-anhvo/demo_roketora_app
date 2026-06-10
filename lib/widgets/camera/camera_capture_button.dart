import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraCaptureButton extends StatefulWidget {
  const CameraCaptureButton({
    super.key,
    required this.state,
    required this.isPhotoMode,
    required this.onPhotoTap,
    this.onQuickVideoStart,
    this.onQuickVideoStop,
    this.enabled = true,
  });

  final CameraState state;
  final bool isPhotoMode;
  final Future<void> Function() onPhotoTap;
  final VoidCallback? onQuickVideoStart;
  final VoidCallback? onQuickVideoStop;
  final bool enabled;

  @override
  State<CameraCaptureButton> createState() => _CameraCaptureButtonState();
}

class _CameraCaptureButtonState extends State<CameraCaptureButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _isQuickRecording = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.12,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isRecording = widget.state is VideoRecordingCameraState;
    final double scale = 1 - _scaleController.value;

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _scaleController.forward() : null,
      onTapUp: widget.enabled ? (_) => _onTapUp() : null,
      onTapCancel: widget.enabled ? () => _scaleController.reverse() : null,
      onLongPressStart: widget.enabled && widget.isPhotoMode
          ? (_) => _onLongPressStart()
          : null,
      onLongPressEnd: widget.enabled && widget.isPhotoMode
          ? (_) => _onLongPressEnd()
          : null,
      child: SizedBox(
        height: 80,
        width: 80,
        child: Transform.scale(
          scale: scale,
          child: CustomPaint(
            painter: _CaptureButtonPainter(
              isVideoMode: !widget.isPhotoMode,
              isRecording: isRecording || _isQuickRecording,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTapUp() async {
    HapticFeedback.selectionClick();
    _scaleController.reverse();

    if (!widget.enabled) return;

    if (widget.isPhotoMode) {
      await widget.onPhotoTap();
      return;
    }

    widget.state.when(
      onVideoMode: (videoState) => videoState.startRecording(),
      onVideoRecordingMode: (recordingState) => recordingState.stopRecording(),
    );
  }

  void _onLongPressStart() {
    if (widget.onQuickVideoStart == null) return;
    HapticFeedback.mediumImpact();
    _scaleController.forward();
    setState(() => _isQuickRecording = true);
    widget.onQuickVideoStart!();
  }

  void _onLongPressEnd() {
    _scaleController.reverse();
    if (!_isQuickRecording) return;
    setState(() => _isQuickRecording = false);
    widget.onQuickVideoStop?.call();
  }
}

class _CaptureButtonPainter extends CustomPainter {
  _CaptureButtonPainter({
    required this.isVideoMode,
    required this.isRecording,
  });

  final bool isVideoMode;
  final bool isRecording;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint outerPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.5);

    final Paint innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, outerPaint);

    if (isRecording) {
      innerPaint.color = Colors.red;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(17, 17, size.width - 34, size.height - 34),
          const Radius.circular(12),
        ),
        innerPaint,
      );
      return;
    }

    innerPaint.color = isVideoMode ? Colors.red : Colors.white;
    canvas.drawCircle(center, radius - 8, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _CaptureButtonPainter oldDelegate) {
    return oldDelegate.isVideoMode != isVideoMode ||
        oldDelegate.isRecording != isRecording;
  }
}
