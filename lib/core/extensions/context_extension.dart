import 'package:flutter/material.dart';

extension NavigatorContext on BuildContext {
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }

  Future<T?> push<T>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(MaterialPageRoute<T>(builder: (_) => page));
  }

  Future<T?> pushFullscreen<T>(Widget page) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute<T>(
        fullscreenDialog: true,
        builder: (_) => page,
      ),
    );
  }

  Future<T?> pushReplacement<T>(Widget page) {
    return Navigator.of(
      this,
    ).pushReplacement<T, dynamic>(MaterialPageRoute<T>(builder: (_) => page));
  }

  Future<T?> pushAndRemoveUntil<T>(Widget page) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(builder: (_) => page),
      (route) => false,
    );
  }

  bool canPop() {
    return Navigator.of(this).canPop();
  }
}
