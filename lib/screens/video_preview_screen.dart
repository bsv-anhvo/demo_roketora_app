import 'package:demo_roketota_app/core/extensions/context_extension.dart';
import 'package:demo_roketota_app/core/extensions/snack_bar_extension.dart';
import 'package:demo_roketota_app/utils/media_file_helper.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/widgets/media/app_video_preview.dart';
import 'package:demo_roketota_app/widgets/common/app_loading_overlay.dart';
import 'package:demo_roketota_app/widgets/common/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({
    super.key,
    required this.filePath,
  });

  /// Stamp video path under cache/roketora_media_stamp.
  final String filePath;

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  bool _isDeleting = false;
  bool _isSaving = false;

  Future<void> _onSave() async {
    if (_isSaving || _isDeleting) return;
    setState(() => _isSaving = true);

    final bool saved =
        await MediaFileHelper.saveConfirmedVideo(widget.filePath);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!saved) {
      Strings.msgCouldNotSaveVideo.showSnackBar(context);
      return;
    }

    context.pop(true);
  }

  Future<void> _onDelete() async {
    if (_isDeleting || _isSaving) return;
    setState(() => _isDeleting = true);
    await MediaFileHelper.deleteIfExists(widget.filePath);
    if (!mounted) return;
    context.pop(false);
  }

  Future<void> _onClosePressed() async {
    if (_isDeleting || _isSaving) return;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.labelDeleteVideoConfirm),
        content: Text(Strings.msgDeleteVideoConfirm),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(Strings.labelActionCancel),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(Strings.labelActionDelete),
          ),
        ],
      ),
    );

    if (!mounted || shouldDelete == null) return;

    if (shouldDelete) {
      await _onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _onClosePressed();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  AppTopBar(
                    title: Strings.labelVideoPreview,
                    leading: IconButton(
                      onPressed: _isDeleting || _isSaving
                          ? null
                          : _onClosePressed,
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: AppVideoPreview(videoPath: widget.filePath),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isDeleting || _isSaving
                                ? null
                                : _onDelete,
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text(Strings.labelActionDelete),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                _isDeleting || _isSaving ? null : _onSave,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(Strings.labelActionSave),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isDeleting)
              AppLoadingOverlay(message: Strings.msgDeleting),
            if (_isSaving) AppLoadingOverlay(message: Strings.msgSaving),
          ],
        ),
      ),
    );
  }
}
