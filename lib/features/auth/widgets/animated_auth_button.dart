import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedAuthButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool outlined;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  
  const AnimatedAuthButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
  }) : super(key: key);

  @override
  State<AnimatedAuthButton> createState() => _AnimatedAuthButtonState();
}

class _AnimatedAuthButtonState extends State<AnimatedAuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
    setState(() {
      _isPressed = true;
    });
  }
  
  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
    setState(() {
      _isPressed = false;
    });
  }
  
  void _handleTapCancel() {
    _animationController.reverse();
    setState(() {
      _isPressed = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = widget.backgroundColor ?? 
        (widget.outlined ? Colors.transparent : primaryColor);
    final textColor = widget.textColor ??
        (widget.outlined ? primaryColor : Colors.white);
    
    return GestureDetector(
      onTapDown: widget.isLoading ? null : _handleTapDown,
      onTapUp: widget.isLoading ? null : _handleTapUp,
      onTapCancel: widget.isLoading ? null : _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.width ?? double.infinity,
              height: 56.h,
              decoration: BoxDecoration(
                gradient: widget.outlined
                    ? null
                    : LinearGradient(
                        colors: [
                          backgroundColor,
                          backgroundColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: widget.outlined ? Colors.transparent : null,
                borderRadius: BorderRadius.circular(16.r),
                border: widget.outlined
                    ? Border.all(
                        color: primaryColor,
                        width: 2,
                      )
                    : null,
                boxShadow: widget.outlined
                    ? []
                    : [
                        if (!_isPressed)
                          BoxShadow(
                            color: backgroundColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.isLoading ? null : widget.onPressed,
                    splashColor: textColor.withValues(alpha: 0.1),
                    highlightColor: textColor.withValues(alpha: 0.05),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.isLoading)
                            SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(textColor),
                              ),
                            )
                          else ...[
                            if (widget.icon != null) ...[
                              widget.icon!,
                              SizedBox(width: 12.w),
                            ],
                            Text(
                              widget.text,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}