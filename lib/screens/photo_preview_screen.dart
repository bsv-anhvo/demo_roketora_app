import 'dart:io';

import 'package:demo_roketota_app/core/extensions/context_extension.dart';
import 'package:demo_roketota_app/utils/media_file_helper.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/widgets/other/app_loading_overlay.dart';
import 'package:demo_roketota_app/widgets/other/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class PhotoPreviewScreen extends StatefulWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.filePath
  });

  final String filePath;

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  bool _isDeleting = false;
  bool isOriginal = false;
  String? pathPhoto;

  String? pathPhotoSave;
  String? _errorMessage;

  void _toggleView() {
    setState(() {
      if (isOriginal) {
        isOriginal = false;
        pathPhoto = pathPhotoSave;
      } else {
        isOriginal = true;
        pathPhoto = widget.filePath;
      }
    });
  }

  Future<void> _onSave() async {
    if (!mounted) return;
    context.pop(true);
  }

  @override
  void initState() {
    super.initState();
    pathPhoto = widget.filePath;
    isOriginal = true;
    runTask();
  }

  void runTask() async {
    try {
      final result = await createPortraitImage(widget.filePath);
      if (mounted) {
        setState(() {
          pathPhotoSave = result;
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error processing image: $e';
        });
      }
    }
  }

  /// Resize dimensions to fit within [maxSize] while maintaining aspect ratio.
  (int, int) _resizeDimensions(int width, int height, int maxSize) {
    if (width > height) {
      return (maxSize, (height * maxSize / width).round());
    }
    return ((width * maxSize / height).round(), maxSize);
  }

  Future<String> createPortraitImage(String imagePath) async {
    final tempDir = await getTemporaryDirectory();

    // Read and decode original image
    final originalBytes = await File(imagePath).readAsBytes();
    final original = img.decodeImage(originalBytes);
    if (original == null) {
      throw Exception('Cannot decode image');
    }

    const int workingSize = 500;
    final (workW, workH) =
        _resizeDimensions(original.width, original.height, workingSize);

    // === 1. Create a working copy at 500px for ALL processing ===
    final working = img.copyResize(original, width: workW, height: workH);

    // === 2. ML Kit segmentation on small image (fast) ===
    final resizedPath =
        '${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(resizedPath).writeAsBytes(img.encodeJpg(working, quality: 85));

    final inputImage = InputImage.fromFilePath(resizedPath);
    final segmenter = SelfieSegmenter(mode: SegmenterMode.single);
    final mask = await segmenter.processImage(inputImage);

    try {
      await File(resizedPath).delete();
    } catch (_) {}

    if (mask == null) {
      throw Exception('Failed to generate segmentation mask');
    }

    // === 3. Blur the working copy (only ~250K pixels vs 12M) ===
    final blurred = img.gaussianBlur(working.clone(), radius: 3);

    // === 4. Apply mask on working copy (small pixel loop) ===
    final outputWork = img.Image.from(working);
    final maskWidth = mask.width;
    final maskHeight = mask.height;

    for (int y = 0; y < workH; y++) {
      for (int x = 0; x < workW; x++) {
        final mx = (x * maskWidth ~/ workW).clamp(0, maskWidth - 1);
        final my = (y * maskHeight ~/ workH).clamp(0, maskHeight - 1);
        final confidence = mask.confidences[my * maskWidth + mx];

        if (confidence < 0.7) {
          outputWork.setPixel(x, y, blurred.getPixel(x, y));
        }
      }
    }

    await segmenter.close();

    // === 5. Scale processed image back to original resolution ===
    final output = img.copyResize(outputWork,
        width: original.width, height: original.height);

    final outputPath =
        '${tempDir.path}/portrait_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await File(outputPath).writeAsBytes(
      img.encodeJpg(output, quality: 95),
    );

    return outputPath;
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
        title: Text(Strings.labelDeletePhotoConfirm),
        content: Text(Strings.msgDeletePhotoConfirm),
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
      title: Strings.labelPhotoPreview,
      leading: IconButton(
        onPressed: _isDeleting ? null : _onClosePressed,
        icon: const Icon(Icons.close_rounded),
        color: Colors.white,
      ),
      trailing: IconButton(
        onPressed: pathPhotoSave == null ? null : _toggleView,
        icon: Icon(
          isOriginal ? Icons.filter_hdr : Icons.image,
          color: Colors.white,
        ),
        tooltip: isOriginal ? 'Xem ảnh chân dung' : 'Xem ảnh gốc',
      ),
    );
  }

  Widget _buildPreview() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final String? displayPath;
    if (isOriginal) {
      displayPath = widget.filePath;
    } else {
      displayPath = pathPhotoSave ?? widget.filePath;
    }

    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: pathPhotoSave == null && pathPhoto == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : Image.file(
                File(displayPath),
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}