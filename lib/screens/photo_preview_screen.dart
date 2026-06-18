import 'dart:io';
import 'dart:typed_data';

import 'package:demo_roketota_app/core/extensions/context_extension.dart';
import 'package:demo_roketota_app/core/extensions/snack_bar_extension.dart';
import 'package:demo_roketota_app/utils/media_file_helper.dart';
import 'package:demo_roketota_app/utils/photo_image_editor_config.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/widgets/common/app_icon_button.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:demo_roketota_app/widgets/common/app_loading_overlay.dart';
import 'package:demo_roketota_app/widgets/common/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PhotoPreviewScreen extends StatefulWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.filePath,
    this.originalFilePath,
  });

  final String filePath;
  final String? originalFilePath;

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  bool _isDeleting = false;
  bool _isSaving = false;
  bool _showOriginal = false;
  String? pathPhotoSave;
  String? _errorMessage;
  String? _editedFilePath;
  bool _isEditing = false;
  String? _editorSourcePath;
  final GlobalKey<ProImageEditorState> _editorKey =
      GlobalKey<ProImageEditorState>();
  late final ProImageEditorCallbacks _imageEditorCallbacks =
      _createImageEditorCallbacks();

  String get _filterStampPath => widget.filePath;

  String? get _originalStampPath =>
      widget.originalFilePath ??
      MediaFileHelper.originalPathForFilter(_filterStampPath);

  String _currentPreviewPath() {
    if (_editedFilePath != null) return _editedFilePath!;
    if (_showOriginal && _originalStampPath != null) {
      return _originalStampPath!;
    }
    return _filterStampPath;
  }

  Future<void> _onSave() async {
    if (_isSaving || _isDeleting) return;
    setState(() => _isSaving = true);

    if (_editedFilePath != null) {
      await File(_editedFilePath!).copy(_filterStampPath);
    }

    final String? originalPath = _originalStampPath;
    if (originalPath == null) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      Strings.msgOriginalFileIsMissing.showSnackBar(context);
      return;
    }

    final bool saved = await MediaFileHelper.saveConfirmedPhoto(
      filterStampPath: _filterStampPath,
      originalStampPath: originalPath,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!saved) {
      Strings.msgCouldNotSaveToGallery.showSnackBar(context);
      return;
    }

    if (_editedFilePath != null) {
      await MediaFileHelper.deleteIfExists(_editedFilePath!);
    }
    if (pathPhotoSave != null) {
      await MediaFileHelper.deleteIfExists(pathPhotoSave!);
    }

    if (!mounted) return;
    context.pop(true);
  }

  void _enterEditMode() {
    if (_isDeleting || _isEditing) return;
    setState(() {
      _isEditing = true;
      _editorSourcePath = _currentPreviewPath();
    });
  }

  void _cancelEditMode() {
    if (!_isEditing) return;
    setState(() {
      _isEditing = false;
      _editorSourcePath = null;
    });
  }

  void _handleEditBackPress() {
    final ProImageEditorState? editorState = _editorKey.currentState;
    if (editorState != null && editorState.isSubEditorOpen) {
      context.pop();
      return;
    }
    _cancelEditMode();
  }

  Future<void> _saveEditedBytes(Uint8List bytes) async {
    final Directory stampDir =
        await MediaFileHelper.mediaStampDirectoryForWrite();
    final String editedPath =
        '${stampDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(editedPath).writeAsBytes(bytes);

    if (!mounted) return;
    setState(() {
      _editedFilePath = editedPath;
      _showOriginal = false;
      _isEditing = false;
      _editorSourcePath = null;
    });
  }

  ProImageEditorCallbacks _createImageEditorCallbacks() {
    return ProImageEditorCallbacks(
      onImageEditingComplete: _saveEditedBytes,
      onCloseEditor: (editorMode) {
        setState(() {
          _isEditing = false;
        });
      },
    );
  }

  Widget _buildInlineImageEditor() {
    final String sourcePath = _editorSourcePath ?? _currentPreviewPath();
    return ProImageEditor.file(
      File(sourcePath),
      key: _editorKey,
      configs: PhotoImageEditorConfig.create(Localizations.localeOf(context)),
      callbacks: _imageEditorCallbacks,
    );
  }

  @override
  void initState() {
    super.initState();
    // Pending portrait photo feature
    // runTask();
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
    final Directory stampDir =
        await MediaFileHelper.mediaStampDirectoryForWrite();

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
        '${stampDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
        '${stampDir.path}/portrait_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await File(outputPath).writeAsBytes(
      img.encodeJpg(output, quality: 95),
    );

    return outputPath;
  }

  Future<void> _onDelete() async {
    if (_isDeleting || _isSaving) return;
    setState(() => _isDeleting = true);

    await MediaFileHelper.deletePhotoStampPair(
      filterStampPath: _filterStampPath,
      originalStampPath: _originalStampPath,
      extraPaths: <String>[
        if (_editedFilePath != null) _editedFilePath!,
        if (pathPhotoSave != null) pathPhotoSave!,
      ],
    );

    if (!mounted) return;
    context.pop(false);
  }

  Future<void> _onClosePressed() async {
    if (_isDeleting || _isSaving) return;
    if (_isEditing) {
      _handleEditBackPress();
      return;
    }

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (_isEditing) {
          _handleEditBackPress();
          return;
        }
        _onClosePressed();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _buildPreview()),
                  _buildBottomBar(),
                ],
              ),
            ),
          if (_isDeleting)
            AppLoadingOverlay(message: Strings.msgDeleting),
          if (_isSaving)
            AppLoadingOverlay(message: Strings.msgSaving),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    if(_isEditing) {
      return SizedBox.shrink();
    } else {
      return AppTopBar(
        title: _isEditing ? Strings.labelEditPhoto : Strings.labelPhotoPreview,
        sideSlotWidth: _isEditing ? 48 : 88,
        leading: AppIconButton(
          onPressed: _isDeleting || _isSaving ? null : _onClosePressed,
          icon: const Icon(Icons.close_rounded),
        ),
        trailing: _isEditing
            ? null
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconButton(
              onPressed: _isDeleting || _isSaving ? null : _enterEditMode,
              icon: const Icon(Icons.edit_outlined),
              tooltip: Strings.labelEditPhoto,
            ),
            // Pending portrait photo feature
            // AppIconButton(
            //   onPressed: pathPhotoSave == null ? null : _toggleView,
            //   icon: Icon(
            //     isOriginal ? Icons.filter_hdr : Icons.image,
            //   ),
            //   tooltip: isOriginal ? 'Xem ảnh chân dung' : 'Xem ảnh gốc',
            // ),
          ],
        ),
      );
    }
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

    if (_isEditing) {
      return _buildInlineImageEditor();
    }

    final String displayPath = _currentPreviewPath();

    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: Image.file(
          File(displayPath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_isEditing) {
      return SizedBox.shrink();
    } else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isDeleting || _isSaving ? null : _onDelete,
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
                onPressed: _isDeleting || _isSaving ? null : _onSave,
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
      );
    }
  }
}
