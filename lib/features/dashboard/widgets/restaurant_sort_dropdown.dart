import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum RestaurantSortType { relevance, open, bestSeller }

class RestaurantSortDropdown extends StatelessWidget {
  final RestaurantSortType selectedSort;
  final Function(RestaurantSortType) onSortChanged;

  const RestaurantSortDropdown({
    Key? key,
    required this.selectedSort,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RestaurantSortType>(
          value: selectedSort,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey[600],
            size: 20.sp,
          ),
          items: [
            DropdownMenuItem(
              value: RestaurantSortType.relevance,
              child: Row(
                children: [
                  Icon(Icons.sort, size: 16.sp, color: Colors.grey[600]),
                  SizedBox(width: 8.w),
                  Text(
                    'Relevance',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: RestaurantSortType.open,
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16.sp, color: Colors.green[600]),
                  SizedBox(width: 8.w),
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: RestaurantSortType.bestSeller,
              child: Row(
                children: [
                  Icon(Icons.star, size: 16.sp, color: Colors.orange[600]),
                  SizedBox(width: 8.w),
                  Text(
                    'Best Seller',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (RestaurantSortType? newSort) {
            if (newSort != null) {
              onSortChanged(newSort);
            }
          },
        ),
      ),
    );
  }
}