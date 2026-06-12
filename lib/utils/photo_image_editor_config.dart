import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class PhotoImageEditorConfig {
  const PhotoImageEditorConfig._();

  static ProImageEditorConfigs create() {
    return ProImageEditorConfigs(
      designMode: ImageEditorDesignMode.material,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
      ),
      mainEditor: const MainEditorConfigs(
        enableSubEditorPage: false,
        tools: [
          SubEditorMode.tune,
          SubEditorMode.filter,
          SubEditorMode.cropRotate,
          SubEditorMode.paint,
          SubEditorMode.text,
        ],
      ),
      paintEditor: const PaintEditorConfigs(
        tools: [
          PaintMode.rect,
          PaintMode.circle,
          PaintMode.arrow,
          PaintMode.line,
          PaintMode.hexagon,
        ],
      ),
    );
  }
}
