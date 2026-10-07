import 'package:flutter/material.dart';
import '../core/constants.dart';

enum PillType { info, success, warning, danger, neutral }

class Pill extends StatelessWidget {
  final String text;
  final PillType type;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const Pill({
    super.key,
    required this.text,
    this.type = PillType.info,
    this.icon,
    this.color,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  const Pill.info({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  }) : type = PillType.info;

  const Pill.success({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  }) : type = PillType.success;

  const Pill.warning({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  }) : type = PillType.warning;

  const Pill.danger({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  }) : type = PillType.danger;

  const Pill.neutral({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  }) : type = PillType.neutral;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (backgroundColor != null && textColor != null) {
      bg = backgroundColor!;
      fg = textColor!;
    } else {
      switch (type) {
        case PillType.info:
          bg = kCyanPale;
          fg = kCyan;
          break;
        case PillType.success:
          bg = kGreenPale;
          fg = kGreen;
          break;
        case PillType.warning:
          bg = kAmberPale;
          fg = kAmber;
          break;
        case PillType.danger:
          bg = kRedPale;
          fg = kRed;
          break;
        case PillType.neutral:
          bg = const Color(0xFFF1F5F9);
          fg = kMuted;
          break;
      }
    }

    if (color != null) {
      fg = color!;
      bg = color!.withOpacity(0.12);
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}