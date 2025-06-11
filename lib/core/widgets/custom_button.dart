import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_typography.dart';

enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Widget? icon;
  final bool outlined;
  final ButtonSize size;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.icon,
    this.outlined = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor;
    final txtColor = textColor ?? (outlined ? bgColor : Colors.white);
    
    // Determine height and font size based on size
    late final double buttonHeight;
    late final double buttonFontSize;
    switch (size) {
      case ButtonSize.small:
        buttonHeight = height ?? 36.h;
        buttonFontSize = 14.sp;
        break;
      case ButtonSize.large:
        buttonHeight = height ?? 60.h;
        buttonFontSize = 18.sp;
        break;
      case ButtonSize.medium:
        buttonHeight = height ?? 50.h;
        buttonFontSize = 16.sp;
    }

    return SizedBox(
      width: width,
      height: buttonHeight,
      child: outlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: bgColor,
                side: BorderSide(color: bgColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(12.r),
                ),
                padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
              ),
              child: _buildChild(txtColor, buttonFontSize),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: txtColor,
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(12.r),
                ),
                padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
                elevation: 0,
              ),
              child: _buildChild(txtColor, buttonFontSize),
            ),
    );
  }

  Widget _buildChild(Color txtColor, double fontSize) {
    if (isLoading) {
      return SizedBox(
        height: 20.h,
        width: 20.h,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(txtColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          SizedBox(width: 8.w),
          Text(
            text,
            style: AppTypography.button.copyWith(
              fontSize: fontSize,
              color: txtColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: AppTypography.button.copyWith(
        fontSize: fontSize,
        color: txtColor,
      ),
    );
  }
}