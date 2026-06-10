import 'dart:io';

import 'package:demo_roketota_app/utils/media_file_helper.dart';
import 'package:demo_roketota_app/widgets/media/app_video_preview.dart';
import 'package:flutter/material.dart';

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
    Navigator.of(context).pop(true);
  }

  Future<void> _onDelete() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    await MediaFileHelper.deleteIfExists(widget.filePath);
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isDeleting ? null : _onDelete,
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      widget.isVideo ? 'Video Preview' : 'Photo Preview',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(child: _buildPreview()),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isDeleting ? null : _onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isDeleting ? null : _onSave,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save'),
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
