import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A widget that displays text aligned to the left and right sides of a row
class LeftRightText extends StatelessWidget {
  final String leftText;
  final String rightText;
  final TextStyle? leftTextStyle;
  final TextStyle? rightTextStyle;

  const LeftRightText({
    super.key,
    required this.leftText,
    required this.rightText,
    this.leftTextStyle,
    this.rightTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            leftText,
            style: leftTextStyle ??
                TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            rightText,
            style: rightTextStyle ??
                TextStyle(
                  fontSize: 12.sp,
                  color: Colors.black87,
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}