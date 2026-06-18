import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:demo_roketota_app/utils/languages/photo_image_editor_i18n.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class PhotoImageEditorConfig {
  const PhotoImageEditorConfig._();

  static ProImageEditorConfigs create(Locale locale) {
    return ProImageEditorConfigs(
      designMode: ImageEditorDesignMode.material,
      i18n: PhotoImageEditorI18n.forLocale(locale),
      filterEditor: FilterEditorConfigs(),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.color30_136_229,
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
