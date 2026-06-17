import 'package:flutter/material.dart';

extension SnackBarExtension on String {
  void showSnackBar(
    BuildContext context, {
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(this),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
  }
}
