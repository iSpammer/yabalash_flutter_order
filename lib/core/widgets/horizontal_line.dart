import 'package:flutter/material.dart';

/// A simple horizontal divider line widget
class HorizontalLine extends StatelessWidget {
  final Color? color;
  final double? height;
  final double? thickness;
  final EdgeInsetsGeometry? margin;

  const HorizontalLine({
    super.key,
    this.color,
    this.height,
    this.thickness,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Divider(
        color: color ?? Colors.grey[200],
        height: height ?? 1,
        thickness: thickness ?? 1,
      ),
    );
  }
}