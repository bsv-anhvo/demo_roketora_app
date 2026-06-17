import 'dart:typed_data';

import 'package:demo_roketota_app/core/extensions/context_extension.dart';
import 'package:demo_roketota_app/utils/media_file_helper.dart';
import 'package:demo_roketota_app/utils/photo_image_editor_config.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/widgets/common/app_icon_button.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:demo_roketota_app/widgets/common/app_loading_overlay.dart';
import 'package:demo_roketota_app/widgets/common/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PhotoPreviewScreen extends StatefulWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.filterBytes,
    this.originalBytes,
  });

  final Uint8List filterBytes;
  final Uint8List? originalBytes;

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  bool _isDeleting = false;
  bool _isSaving = false;
  bool _showOriginal = false;
  bool _isEditing = false;
  Uint8List? _editedBytes;
  Uint8List? _editorSourceBytes;
  final GlobalKey<ProImageEditorState> _editorKey =
      GlobalKey<ProImageEditorState>();
  late final ProImageEditorCallbacks _imageEditorCallbacks =
      _createImageEditorCallbacks();

  Uint8List get _filterBytes => widget.filterBytes;

  Uint8List get _originalBytes => widget.originalBytes ?? widget.filterBytes;

  Uint8List get _displayBytes {
    if (_editedBytes != null) return _editedBytes!;
    if (_showOriginal) return _originalBytes;
    return _filterBytes;
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final Uint8List filterForGallery = _editedBytes ?? _filterBytes;
    final bool saved = await MediaFileHelper.saveConfirmedPhoto(
      filterBytes: filterForGallery,
      originalBytes: _originalBytes,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save to Gallery. '
            'Please fully restart the app (flutter run).',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    context.pop(true);
  }

  void _enterEditMode() {
    if (_isDeleting || _isSaving || _isEditing) return;
    setState(() {
      _isEditing = true;
      _editorSourceBytes = Uint8List.fromList(_displayBytes);
    });
  }

  void _cancelEditMode() {
    if (!_isEditing) return;
    setState(() {
      _isEditing = false;
      _editorSourceBytes = null;
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
    if (!mounted) return;
    setState(() {
      _editedBytes = bytes;
      _showOriginal = false;
      _isEditing = false;
      _editorSourceBytes = null;
    });
  }

  ProImageEditorCallbacks _createImageEditorCallbacks() {
    return ProImageEditorCallbacks(
      onImageEditingComplete: _saveEditedBytes,
      onCloseEditor: (_) {
        setState(() => _isEditing = false);
      },
    );
  }

  Widget _buildInlineImageEditor() {
    final Uint8List sourceBytes =
        _editorSourceBytes ?? Uint8List.fromList(_displayBytes);
    return ProImageEditor.memory(
      sourceBytes,
      key: _editorKey,
      configs: PhotoImageEditorConfig.create(),
      callbacks: _imageEditorCallbacks,
    );
  }

  Future<void> _onDelete() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
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
                  if (!_isEditing)
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

  Widget _buildTopBar() {
    if (_isEditing) {
      return const SizedBox.shrink();
    }

    return AppTopBar(
      title: Strings.labelPhotoPreview,
      sideSlotWidth: 88,
      leading: AppIconButton(
        onPressed: _isDeleting || _isSaving ? null : _onClosePressed,
        icon: const Icon(Icons.close_rounded),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton(
            onPressed: _isDeleting || _isSaving ? null : _enterEditMode,
            icon: const Icon(Icons.edit_outlined),
            tooltip: Strings.labelEditPhoto,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_isEditing) {
      return _buildInlineImageEditor();
    }

    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: Image.memory(
          _displayBytes,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
