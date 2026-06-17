import 'package:flutter/material.dart';

class Constants {
  static const Duration quickRecordMaxDuration = Duration(seconds: 10);
  static const Duration videoRecordMaxDuration = Duration(seconds: 20);

  static const double buttonSize = 80;
  static const double ringSize = 96;

  static const BoxConstraints topBarIconConstraints = BoxConstraints(
    minWidth: 40,
    minHeight: 40,
  );
}
