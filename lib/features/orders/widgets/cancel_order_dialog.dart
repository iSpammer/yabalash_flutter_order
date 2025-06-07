import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CancelOrderDialog extends StatefulWidget {
  final Function(int reasonId, String? customReason) onConfirm;
  final List<CancelReason> reasons;

  const CancelOrderDialog({
    super.key,
    required this.onConfirm,
    required this.reasons,
  });

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  CancelReason? selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _showCustomReasonField = false;
  String? _customReasonError;

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for cancellation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if custom reason is required and provided
    if (selectedReason!.id == 8 && _customReasonController.text.trim().isEmpty) {
      setState(() {
        _customReasonError = 'Please provide a reason';
      });
      return;
    }

    Navigator.of(context).pop();
    widget.onConfirm(
      selectedReason!.id,
      selectedReason!.id == 8 ? _customReasonController.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    color: Colors.red,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Cancel Order',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      size: 20.sp,
                      color: Colors.grey[600],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please select a reason for cancellation:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    
                    // Reasons list
                    ...widget.reasons.map((reason) => RadioListTile<CancelReason>(
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                          _showCustomReasonField = value?.id == 8;
                          if (!_showCustomReasonField) {
                            _customReasonController.clear();
                            _customReasonError = null;
                          }
                        });
                      },
                      title: Text(
                        reason.title,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                      dense: true,
                    )),
                    
                    // Custom reason text field
                    if (_showCustomReasonField) ...[
                      SizedBox(height: 16.h),
                      TextField(
                        controller: _customReasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Please specify your reason...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          errorText: _customReasonError,
                          contentPadding: EdgeInsets.all(12.w),
                        ),
                        onChanged: (value) {
                          if (_customReasonError != null) {
                            setState(() {
                              _customReasonError = null;
                            });
                          }
                        },
                      ),
                    ],
                    
                    SizedBox(height: 16.h),
                    
                    // Warning message
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Order cancellation may affect your account rating. Please cancel only if necessary.',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.orange[900],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: Text(
                        'Keep Order',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'Cancel Order',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CancelReason {
  final int id;
  final String title;

  const CancelReason({
    required this.id,
    required this.title,
  });

  factory CancelReason.fromJson(Map<String, dynamic> json) {
    return CancelReason(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
    );
  }
}