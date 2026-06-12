import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.titleStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.sideSlotWidth = 48,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry padding;
  final double sideSlotWidth;

  @override
  Widget build(BuildContext context) {
    final TextStyle resolvedTitleStyle =
        titleStyle ??
        TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          SizedBox(
            width: sideSlotWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: leading,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: resolvedTitleStyle,
            ),
          ),
          SizedBox(
            width: sideSlotWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing,
            ),
          ),
        ],
      ),
    );
  }
}
