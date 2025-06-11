import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../features/cart/providers/cart_provider.dart';
import '../theme/app_colors.dart';

class V2BottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const V2BottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<V2BottomNavigation> createState() => _V2BottomNavigationState();
}

class _V2BottomNavigationState extends State<V2BottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.15,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();

    _rotationAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 0.1,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    // Animate the current index
    if (widget.currentIndex >= 0 && widget.currentIndex < 4) {
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(V2BottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Reverse old animation
      if (oldWidget.currentIndex >= 0 && oldWidget.currentIndex < 4) {
        _controllers[oldWidget.currentIndex].reverse();
      }
      // Forward new animation
      if (widget.currentIndex >= 0 && widget.currentIndex < 4) {
        _controllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      child: Stack(
        children: [
          // Blur effect background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 80.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.2),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.primaryColor.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Navigation items
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80.h,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildCartNavItem(),
                  _buildNavItem(2, Icons.receipt_long_rounded, 'Orders'),
                  _buildNavItem(3, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),

          // Animated indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            bottom: 75.h,
            left: 20.w +
                (widget.currentIndex *
                    ((MediaQuery.of(context).size.width - 40.w) / 4)),
            child: Container(
              width: (MediaQuery.of(context).size.width - 40.w) / 4,
              height: 3.h,
              child: Center(
                child: Container(
                  width: 30.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(2.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: Transform.rotate(
                angle: _rotationAnimations[index].value,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isActive
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryColor
                                        .withValues(alpha: 0.2),
                                    AppColors.primaryColor
                                        .withValues(alpha: 0.1),
                                  ],
                                )
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: isActive
                              ? AppColors.primaryColor
                              : Colors.grey[600],
                          size: isActive ? 22.sp : 20.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isActive ? 10.sp : 9.sp,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? AppColors.primaryColor
                              : Colors.grey[600],
                          letterSpacing: isActive ? 0.5 : 0.0,
                        ),
                        child: Text(label),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCartNavItem() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final isActive = widget.currentIndex == 1;
        final itemCount = cartProvider.itemCount;

        return Expanded(
          child: GestureDetector(
            onTap: () => widget.onTap(1),
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _controllers[1],
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimations[1].value,
                  child: Transform.rotate(
                    angle: _rotationAnimations[1].value,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isActive
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primaryColor
                                            .withValues(alpha: 0.2),
                                        AppColors.primaryColor
                                            .withValues(alpha: 0.1),
                                      ],
                                    )
                                  : null,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.shopping_cart_rounded,
                                  color: isActive
                                      ? AppColors.primaryColor
                                      : Colors.grey[600],
                                  size: isActive ? 26.sp : 24.sp,
                                ),
                                if (itemCount > 0)
                                  Positioned(
                                    right: -8,
                                    top: -8,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration:
                                          const Duration(milliseconds: 500),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            padding: EdgeInsets.all(4.w),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppColors.primaryColor,
                                                  AppColors.primaryColorDark,
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primaryColor
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            constraints: BoxConstraints(
                                              minWidth: 20.w,
                                              minHeight: 20.h,
                                            ),
                                            child: Center(
                                              child: Text(
                                                itemCount > 99
                                                    ? '99+'
                                                    : itemCount.toString(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: isActive ? 11.sp : 10.sp,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive
                                  ? AppColors.primaryColor
                                  : Colors.grey[600],
                              letterSpacing: isActive ? 0.5 : 0.0,
                            ),
                            child: const Text('Cart'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
