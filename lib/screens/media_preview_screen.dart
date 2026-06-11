import 'dart:io';

import 'package:demo_roketota_app/core/extensions/context_extension.dart';
import 'package:demo_roketota_app/utils/media_file_helper.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/widgets/media/app_video_preview.dart';
import 'package:demo_roketota_app/widgets/other/app_loading_overlay.dart';
import 'package:demo_roketota_app/widgets/other/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class MediaPreviewScreen extends StatefulWidget {
  const MediaPreviewScreen({
    super.key,
    required this.filePath,
    required this.isVideo,
  });

  final String filePath;
  final bool isVideo;

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  bool _isDeleting = false;

  Future<void> _onSave() async {
    if (!mounted) return;
    context.pop(true);
  }

  Future<void> _onDelete() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    await MediaFileHelper.deleteIfExists(widget.filePath);
    if (!mounted) return;
    context.pop(false);
  }

  Future<void> _onClosePressed() async {
    if (_isDeleting) return;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isVideo ? Strings.labelDeleteVideoConfirm : Strings.labelDeletePhotoConfirm),
        content: Text(
          widget.isVideo
              ? Strings.msgDeleteVideoConfirm
              : Strings.msgDeletePhotoConfirm,
        ),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildPreview()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isDeleting ? null : _onDelete,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(Strings.labelActionDelete),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isDeleting ? null : _onSave,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(Strings.labelActionSave),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return AppTopBar(
      title: widget.isVideo ? Strings.labelVideoPreview : Strings.labelPhotoPreview,
      leading: IconButton(
        onPressed: _isDeleting ? null : _onClosePressed,
        icon: const Icon(Icons.close_rounded),
        color: Colors.white,
      ),
    );
  }

  Widget _buildPreview() {
    if (widget.isVideo) {
      return AppVideoPreview(videoPath: widget.filePath);
    }

    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: Image.file(
          File(widget.filePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
