import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/cart_model.dart';

class PromoCodeSection extends StatefulWidget {
  final int vendorId;
  final CouponData? appliedCoupon;
  final Function(String) onApplyCode;
  final VoidCallback onRemoveCode;

  const PromoCodeSection({
    Key? key,
    required this.vendorId,
    this.appliedCoupon,
    required this.onApplyCode,
    required this.onRemoveCode,
  }) : super(key: key);

  @override
  State<PromoCodeSection> createState() => _PromoCodeSectionState();
}

class _PromoCodeSectionState extends State<PromoCodeSection> {
  final _promoCodeController = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appliedCoupon != null) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.green[300]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_offer,
              size: 20.sp,
              color: Colors.green[700],
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code ${widget.appliedCoupon!.name} Applied',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  if (widget.appliedCoupon!.amount != null)
                    Text(
                      'You saved AED ${widget.appliedCoupon!.amount!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green[600],
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onRemoveCode,
              child: Text(
                'Remove',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer,
                    size: 20.sp,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Apply Promo Code',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 24.sp,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoCodeController,
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () {
                      final code = _promoCodeController.text.trim();
                      if (code.isNotEmpty) {
                        widget.onApplyCode(code);
                        _promoCodeController.clear();
                        setState(() {
                          _isExpanded = false;
                        });
                      }
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}