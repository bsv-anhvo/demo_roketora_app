import 'dart:math' as math;

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
    this.onVideoRecordStop,
    this.onHoldRecordingChanged,
    this.recordMaxDuration,
    this.enabled = true,
  });

  static const Duration quickRecordMaxDuration = Duration(seconds: 10);
  static const Duration videoRecordMaxDuration = Duration(seconds: 20);

  final CameraState state;
  final bool isPhotoMode;
  final Future<void> Function() onPhotoTap;
  final VoidCallback? onQuickVideoStart;
  final VoidCallback? onQuickVideoStop;
  final VoidCallback? onVideoRecordStop;
  final ValueChanged<bool>? onHoldRecordingChanged;

  /// When set in video mode, draws a countdown ring and auto-stops recording.
  final Duration? recordMaxDuration;
  final bool enabled;

  @override
  State<CameraCaptureButton> createState() => _CameraCaptureButtonState();
}

class _CameraCaptureButtonState extends State<CameraCaptureButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _progressController;
  bool _isQuickRecording = false;
  bool _wasLongPress = false;

  static const double _buttonSize = 80;
  static const double _ringSize = 96;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.12,
    );
    _progressController = AnimationController(vsync: this)
      ..addStatusListener(_onProgressStatusChanged);
  }

  void _onProgressStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    if (_isQuickRecording) {
      _finishQuickRecording();
      return;
    }

    _autoStopVideoRecording();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  bool get _showsRecordProgressRing {
    if (_isQuickRecording) return true;
    if (widget.isPhotoMode || widget.recordMaxDuration == null) return false;
    return widget.state is VideoRecordingCameraState ||
        _progressController.isAnimating;
  }

  bool get _supportsHoldRecord =>
      widget.onQuickVideoStart != null && widget.onQuickVideoStop != null;

  @override
  Widget build(BuildContext context) {
    final bool isRecording = widget.state is VideoRecordingCameraState;
    final double scale = 1 - _scaleController.value;

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _scaleController.forward() : null,
      onTapUp: widget.enabled ? (_) => _onTapUp() : null,
      onTapCancel: widget.enabled ? _onTapCancel : null,
      onLongPressStart: widget.enabled && _supportsHoldRecord
          ? (_) => _onLongPressStart()
          : null,
      onLongPressEnd: widget.enabled && _supportsHoldRecord
          ? (_) => _onLongPressEnd()
          : null,
      child: SizedBox(
        height: _ringSize,
        width: _ringSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_showsRecordProgressRing)
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(_ringSize, _ringSize),
                    painter: _ProgressRingPainter(
                      progress: _progressController.value,
                    ),
                  );
                },
              ),
            Transform.scale(
              scale: scale,
              child: SizedBox(
                height: _buttonSize,
                width: _buttonSize,
                child: CustomPaint(
                  painter: _CaptureButtonPainter(
                    isVideoMode: !widget.isPhotoMode,
                    isRecording: isRecording || _isQuickRecording,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTapUp() async {
    HapticFeedback.selectionClick();
    _scaleController.reverse();

    if (!widget.enabled || _wasLongPress) {
      _wasLongPress = false;
      return;
    }

    if (widget.isPhotoMode) {
      await widget.onPhotoTap();
      return;
    }

    widget.state.when(
      onVideoMode: (videoState) {
        videoState.startRecording();
        _startVideoRecordProgress();
      },
      onVideoRecordingMode: (recordingState) {
        _resetRecordProgress();
        widget.onVideoRecordStop?.call();
        recordingState.stopRecording();
      },
    );
  }

  void _onTapCancel() {
    _scaleController.reverse();
    _wasLongPress = false;
  }

  void _onLongPressStart() {
    if (widget.onQuickVideoStart == null) return;
    HapticFeedback.mediumImpact();
    _wasLongPress = true;
    _scaleController.forward();
    setState(() => _isQuickRecording = true);
    widget.onHoldRecordingChanged?.call(true);
    _progressController
      ..duration = widget.isPhotoMode
          ? CameraCaptureButton.quickRecordMaxDuration
          : (widget.recordMaxDuration ??
              CameraCaptureButton.quickRecordMaxDuration)
      ..forward(from: 0);
    widget.onQuickVideoStart!();
  }

  void _onLongPressEnd() {
    _finishQuickRecording();
  }

  void _finishQuickRecording() {
    if (!_isQuickRecording) return;

    _resetRecordProgress();
    _scaleController.reverse();
    setState(() => _isQuickRecording = false);
    widget.onHoldRecordingChanged?.call(false);
    widget.onQuickVideoStop?.call();
  }

  void _startVideoRecordProgress() {
    final Duration? maxDuration = widget.recordMaxDuration;
    if (maxDuration == null) return;

    _progressController
      ..duration = maxDuration
      ..forward(from: 0);
    setState(() {});
  }

  void _resetRecordProgress() {
    _progressController
      ..stop()
      ..reset();
  }

  void _autoStopVideoRecording() {
    if (widget.isPhotoMode || widget.recordMaxDuration == null) return;

    _resetRecordProgress();
    HapticFeedback.mediumImpact();
    widget.state.when(
      onVideoRecordingMode: (recordingState) {
        widget.onVideoRecordStop?.call();
        recordingState.stopRecording();
      },
      onPhotoMode: (_) {},
      onVideoMode: (_) {},
      onPreviewMode: (_) {},
      onAnalysisOnlyMode: (_) {},
    );
    if (mounted) setState(() {});
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 5;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    final Paint trackPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final Paint progressPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
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
