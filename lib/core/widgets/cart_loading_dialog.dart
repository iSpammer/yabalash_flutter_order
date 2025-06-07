import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartLoadingDialog extends StatelessWidget {
  final String message;
  static bool _isShowing = false;
  static BuildContext? _dialogContext;

  const CartLoadingDialog({
    Key? key,
    this.message = 'Adding to cart...',
  }) : super(key: key);

  static void show(BuildContext context, {String message = 'Adding to cart...'}) {
    debugPrint('CartLoadingDialog.show called with message: $message');
    
    if (_isShowing) {
      debugPrint('CartLoadingDialog already showing, hiding first');
      // If already showing, hide it first
      hideForce(context);
    }
    
    _isShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        _dialogContext = dialogContext;
        return CartLoadingDialog(message: message);
      },
    ).then((_) {
      debugPrint('CartLoadingDialog dismissed via showDialog future');
      _isShowing = false;
      _dialogContext = null;
    });
  }

  static void hide(BuildContext context) {
    debugPrint('CartLoadingDialog.hide called, _isShowing: $_isShowing');
    if (!_isShowing) return;
    
    // Mark as not showing immediately to prevent race conditions
    _isShowing = false;
    
    // Add a small delay to ensure all operations are complete
    Future.delayed(const Duration(milliseconds: 100), () {
      // Try to use the stored dialog context first
      if (_dialogContext != null && _dialogContext!.mounted) {
        try {
          debugPrint('CartLoadingDialog.hide - using stored dialog context');
          Navigator.of(_dialogContext!).pop();
          _dialogContext = null;
          return;
        } catch (e) {
          debugPrint('Error closing with dialog context: $e');
        }
      }
      
      // Fallback to using the provided context
      if (context.mounted && Navigator.of(context).canPop()) {
        debugPrint('CartLoadingDialog.hide - popping dialog with provided context');
        Navigator.of(context).pop();
      } else {
        debugPrint('CartLoadingDialog.hide - cannot pop or context not mounted');
      }
      
      _dialogContext = null;
    });
  }
  
  static void hideForce(BuildContext context) {
    debugPrint('CartLoadingDialog.hideForce called, _isShowing: $_isShowing');
    _isShowing = false;
    
    // Try to use the stored dialog context first
    if (_dialogContext != null && _dialogContext!.mounted) {
      try {
        debugPrint('CartLoadingDialog.hideForce - using stored dialog context');
        Navigator.of(_dialogContext!).pop();
        _dialogContext = null;
        return;
      } catch (e) {
        debugPrint('Error closing with dialog context: $e');
      }
    }
    
    // Fallback to using the provided context
    if (context.mounted) {
      try {
        // Find and close all dialogs
        Navigator.of(context).popUntil((route) {
          // Continue popping if this is a dialog
          if (route is DialogRoute || route is PopupRoute || route.settings.name == null) {
            debugPrint('CartLoadingDialog.hideForce - found dialog route: ${route.runtimeType}');
            return false; // Keep popping
          }
          return true; // Stop at non-dialog routes
        });
        debugPrint('CartLoadingDialog.hideForce - completed');
      } catch (e) {
        debugPrint('Error force closing dialogs: $e');
      }
    } else {
      debugPrint('CartLoadingDialog.hideForce - context not mounted');
    }
    
    _dialogContext = null;
  }

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