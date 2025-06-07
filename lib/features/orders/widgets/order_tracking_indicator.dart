import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderTrackingIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? statusIcons;
  final List<String> stepTitles;
  final List<String> stepDescriptions;

  const OrderTrackingIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 6,
    this.statusIcons,
    required this.stepTitles,
    required this.stepDescriptions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStepIndicator(context),
        SizedBox(height: 20.h),
        _buildStepDetails(context),
      ],
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              // This is a line between steps
              final stepIndex = index ~/ 2;
              final isCompleted = currentStep > stepIndex + 1;
              return Expanded(
                child: Container(
                  height: 2.h,
                  color: isCompleted 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[300],
                ),
              );
            } else {
              // This is a step
              final stepIndex = index ~/ 2;
              final isCompleted = currentStep > stepIndex + 1;
              final isActive = currentStep == stepIndex + 1;
              
              return _buildStepCircle(
                context,
                stepIndex + 1,
                isCompleted,
                isActive,
                (statusIcons?.length ?? 0) > stepIndex ? statusIcons![stepIndex] : null,
              );
            }
          }),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            return Expanded(
              child: Text(
                stepTitles.length > index ? stepTitles[index] : '',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: currentStep >= index + 1 
                      ? Colors.black87 
                      : Colors.grey[500],
                  fontWeight: currentStep == index + 1 
                      ? FontWeight.w600 
                      : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStepCircle(BuildContext context, int step, bool isCompleted, bool isActive, String? iconUrl) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? Theme.of(context).primaryColor
            : Colors.grey[300],
        border: Border.all(
          color: isActive 
              ? Theme.of(context).primaryColor 
              : Colors.transparent,
          width: 3.w,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: 20.sp,
              )
            : isActive && iconUrl != null
                ? _buildStepIcon(iconUrl)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
      ),
    );
  }

  Widget _buildStepIcon(String iconUrl) {
    // For now, return a default icon
    // In a real app, you'd load the icon from the URL
    return Icon(
      _getIconForStep(currentStep),
      color: Colors.white,
      size: 20.sp,
    );
  }

  IconData _getIconForStep(int step) {
    switch (step) {
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.person;
      case 3:
        return Icons.directions_car;
      case 4:
        return Icons.store;
      case 5:
        return Icons.shopping_bag;
      case 6:
        return Icons.home;
      default:
        return Icons.circle;
    }
  }

  Widget _buildStepDetails(BuildContext context) {
    if (currentStep <= 0 || currentStep > stepDescriptions.length) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            _getIconForStep(currentStep),
            size: 48.sp,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(height: 12.h),
          Text(
            stepTitles.length >= currentStep ? stepTitles[currentStep - 1] : '',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            stepDescriptions.length >= currentStep ? stepDescriptions[currentStep - 1] : '',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}