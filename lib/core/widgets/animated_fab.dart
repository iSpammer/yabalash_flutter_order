import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool mini;
  final bool extended;

  const AnimatedFAB({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = false,
    this.extended = false,
  }) : super(key: key);

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));
    
    // Add a subtle pulse animation
    _startPulseAnimation();
  }

  void _startPulseAnimation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _scaleController.forward().then((_) {
          _scaleController.reverse().then((_) {
            _startPulseAnimation();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _rotateController.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppColors.primaryColor;
    final foregroundColor = widget.foregroundColor ?? Colors.white;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _rotateAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: _handleTap,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              elevation: 8,
              isExtended: widget.extended || widget.label != null,
              icon: Transform.rotate(
                angle: _rotateAnimation.value,
                child: Icon(
                  widget.icon,
                  size: widget.mini ? 20.sp : 24.sp,
                ),
              ),
              label: widget.label != null
                  ? Text(
                      widget.label!,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedExpandableFAB extends StatefulWidget {
  final List<AnimatedFABMenuItem> items;
  final IconData icon;
  final IconData? closeIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AnimatedExpandableFAB({
    Key? key,
    required this.items,
    required this.icon,
    this.closeIcon,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  State<AnimatedExpandableFAB> createState() => _AnimatedExpandableFABState();
}

class _AnimatedExpandableFABState extends State<AnimatedExpandableFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppColors.primaryColor;
    final foregroundColor = widget.foregroundColor ?? Colors.white;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _expandAnimation.value,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    (1 - _expandAnimation.value) * 50,
                  ),
                  child: Opacity(
                    opacity: _expandAnimation.value,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (item.label != null)
                            Container(
                              margin: EdgeInsets.only(right: 12.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                item.label!,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          FloatingActionButton(
                            mini: true,
                            onPressed: item.onPressed,
                            backgroundColor: item.backgroundColor ?? backgroundColor,
                            foregroundColor: item.foregroundColor ?? foregroundColor,
                            heroTag: 'fab_menu_item_$index',
                            child: Icon(
                              item.icon,
                              size: 20.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList().reversed,
        AnimatedFAB(
          onPressed: _toggle,
          icon: _isExpanded ? (widget.closeIcon ?? Icons.close) : widget.icon,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
      ],
    );
  }
}

class AnimatedFABMenuItem {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AnimatedFABMenuItem({
    required this.icon,
    this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });
}