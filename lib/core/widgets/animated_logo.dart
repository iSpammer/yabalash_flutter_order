import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class AnimatedYabalashLogo extends StatefulWidget {
  final double? width;
  final double? height;
  final bool showAnimation;
  final Color? color;

  const AnimatedYabalashLogo({
    Key? key,
    this.width,
    this.height,
    this.showAnimation = true,
    this.color,
  }) : super(key: key);

  @override
  State<AnimatedYabalashLogo> createState() => _AnimatedYabalashLogoState();
}

class _AnimatedYabalashLogoState extends State<AnimatedYabalashLogo>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.showAnimation) {
      _scaleController.forward();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoWidget = Container(
      width: widget.width ?? 120.w,
      height: widget.height ?? 120.w,
      decoration: BoxDecoration(
        color: widget.color ?? AppColors.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (widget.color ?? AppColors.primaryColor).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'يا\nبلاش',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: (widget.width ?? 120.w) * 0.25,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.2,
            fontFamily: 'Arial',
          ),
        ),
      ),
    );

    if (!widget.showAnimation) {
      return logoWidget;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _rotationAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 30 * _scaleAnimation.value,
                  spreadRadius: 10 * _scaleAnimation.value,
                ),
              ],
            ),
            child: logoWidget,
          ),
        );
      },
    );
  }
}

class YabalashLogoSmall extends StatelessWidget {
  final double? size;
  final Color? color;

  const YabalashLogoSmall({
    Key? key,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? 40.w,
      height: size ?? 40.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color ?? AppColors.primaryColor,
            (color ?? AppColors.primaryColor).withValues(alpha: 0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (color ?? AppColors.primaryColor).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'يا',
          style: TextStyle(
            fontSize: (size ?? 40.w) * 0.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: 'Arial',
          ),
        ),
      ),
    );
  }
}