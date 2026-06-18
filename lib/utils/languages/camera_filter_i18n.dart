import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_roketota_app/utils/languages/photo_image_editor_i18n.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:flutter/material.dart';

/// Localized display names for [AwesomeFilter] presets in the camera UI.
class CameraFilterI18n {
  const CameraFilterI18n._();

  static String displayName(AwesomeFilter filter, Locale locale) {
    if (filter.id == AwesomeFilter.None.id) {
      return Strings.labelOriginal;
    }

    return PhotoImageEditorI18n.filtersFor(
      locale,
    ).getFilterI18n(_lookupKey(filter.name));
  }

  /// Maps Camerawesome filter names to pro_image_editor lookup keys.
  static String _lookupKey(String name) {
    return switch (name) {
      'Addictive Blue' => 'AddictiveBlue',
      'Addictive Red' => 'AddictiveRed',
      _ => name,
    };
  }
}
