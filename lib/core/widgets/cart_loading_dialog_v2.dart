import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartLoadingDialogV2 {
  static bool _isShowing = false;
  
  static void show(BuildContext context, {String message = 'Adding to cart...'}) {
    if (_isShowing) return; // Prevent multiple dialogs
    
    _isShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _CartLoadingDialogWidget(message: message);
      },
    ).then((_) {
      _isShowing = false;
    });
  }
  
  static Future<void> hide(BuildContext context) async {
    if (!_isShowing) return;
    
    // Add a small delay to ensure all operations are complete
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      _isShowing = false;
    }
  }
  
  static Future<void> hideForce(BuildContext context) async {
    _isShowing = false;
    
    // Try multiple times to ensure dialog is closed
    for (int i = 0; i < 3; i++) {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

class _CartLoadingDialogWidget extends StatelessWidget {
  final String message;

  const _CartLoadingDialogWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated cart icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      size: 40.sp,
                      color: Colors.green,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}