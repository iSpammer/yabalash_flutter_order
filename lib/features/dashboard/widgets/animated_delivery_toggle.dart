import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../cart/providers/cart_provider.dart';
import 'delivery_pickup_toggle.dart';

class AnimatedDeliveryToggle extends StatefulWidget {
  final DeliveryMode selectedMode;
  final Function(DeliveryMode) onModeChanged;
  final Color? backgroundColor;
  final Color? selectedColor;

  const AnimatedDeliveryToggle({
    Key? key,
    required this.selectedMode,
    required this.onModeChanged,
    this.backgroundColor,
    this.selectedColor,
  }) : super(key: key);

  @override
  State<AnimatedDeliveryToggle> createState() => _AnimatedDeliveryToggleState();
}

class _AnimatedDeliveryToggleState extends State<AnimatedDeliveryToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: widget.selectedMode == DeliveryMode.delivery ? 0.0 : 0.5,
      end: widget.selectedMode == DeliveryMode.delivery ? 0.0 : 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedDeliveryToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMode != widget.selectedMode) {
      _animateToMode(widget.selectedMode);
    }
  }

  void _animateToMode(DeliveryMode mode) {
    _slideAnimation = Tween<double>(
      begin: _slideAnimation.value,
      end: mode == DeliveryMode.delivery ? 0.0 : 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? Colors.grey[100]!;
    final selectedColor = widget.selectedColor ?? Colors.white;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      height: 56.h,
      child: Stack(
        children: [
          // Background container
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
          ),
          // Animated selection indicator
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Positioned(
                left: 4.w + (_slideAnimation.value * (MediaQuery.of(context).size.width - 40.w)),
                top: 4.h,
                bottom: 4.h,
                width: (MediaQuery.of(context).size.width - 40.w) / 2,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // Toggle buttons
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  context,
                  mode: DeliveryMode.delivery,
                  icon: Icons.delivery_dining,
                  label: 'Delivery',
                  isSelected: widget.selectedMode == DeliveryMode.delivery,
                ),
              ),
              Expanded(
                child: _buildToggleButton(
                  context,
                  mode: DeliveryMode.pickup,
                  icon: Icons.store,
                  label: 'Pickup',
                  isSelected: widget.selectedMode == DeliveryMode.pickup,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required DeliveryMode mode,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _handleModeChange(context, mode),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                icon,
                key: ValueKey('${mode.toString()}_$isSelected'),
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                size: isSelected ? 22.sp : 20.sp,
              ),
            ),
            SizedBox(width: 8.w),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 15.sp : 14.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  void _handleModeChange(BuildContext context, DeliveryMode newMode) {
    if (widget.selectedMode != newMode) {
      // Add haptic feedback
      // HapticFeedback.lightImpact();
      
      widget.onModeChanged(newMode);
    }
  }
}