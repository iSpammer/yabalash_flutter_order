import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ScheduleOrderWidget extends StatelessWidget {
  final String scheduleType;
  final DateTime? scheduledDateTime;
  final Function(String, DateTime?) onScheduleChanged;

  const ScheduleOrderWidget({
    Key? key,
    required this.scheduleType,
    this.scheduledDateTime,
    required this.onScheduleChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Time',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),

          // Schedule type options
          Row(
            children: [
              _buildScheduleOption(
                context,
                'Now',
                'now',
                Icons.flash_on,
              ),
              SizedBox(width: 12.w),
              _buildScheduleOption(
                context,
                'Schedule',
                'schedule',
                Icons.schedule,
              ),
            ],
          ),

          // Show date time picker if schedule is selected
          if (scheduleType == 'schedule')
            Column(
              children: [
                SizedBox(height: 16.h),
                InkWell(
                  onTap: () => _selectDateTime(context),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20.sp,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            scheduledDateTime != null
                                ? DateFormat('MMM dd, yyyy - hh:mm a')
                                    .format(scheduledDateTime!)
                                : 'Select date and time',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: scheduledDateTime != null
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20.sp,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleOption(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final isSelected = scheduleType == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (value == 'now') {
            onScheduleChanged('now', null);
          } else {
            onScheduleChanged('schedule', scheduledDateTime);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = scheduledDateTime ?? now.add(const Duration(hours: 1));

    // First, select date
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );

    if (selectedDate != null) {
      // Then, select time
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (selectedTime != null) {
        final newDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        // Validate the selected time is in the future
        if (newDateTime.isAfter(now)) {
          onScheduleChanged('schedule', newDateTime);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a future time'),
            ),
          );
        }
      }
    }
  }
}