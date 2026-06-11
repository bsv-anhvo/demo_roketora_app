import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.titleStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry padding;

  static const double _sideSlotWidth = 48;

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
          if (leading != null)
            leading!
          else
            const SizedBox(width: _sideSlotWidth),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: resolvedTitleStyle,
            ),
          ),
          SizedBox(
            width: _sideSlotWidth,
            child: trailing == null
                ? null
                : Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}
