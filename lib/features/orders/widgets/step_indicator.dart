import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StepIndicatorWidget extends StatelessWidget {
  final List<String> labels;
  final int currentPosition;

  const StepIndicatorWidget({
    super.key,
    required this.labels,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(labels.length, (index) {
          final isCompleted = index <= currentPosition;
          final isActive = index == currentPosition;
          
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2.h,
                          color: isCompleted 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey[300],
                        ),
                      ),
                    Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[300],
                        boxShadow: isActive 
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withAlpha(77), // 0.3 * 255 = 77
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16.sp,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    if (index < labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 2.h,
                          color: index < currentPosition 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}