import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/order_model.dart';

class ReturnOrderModal extends StatefulWidget {
  final OrderModel order;
  final List<OrderProductModel> products;
  final bool isReplace;
  final Function(List<int> productIds) onConfirm;

  const ReturnOrderModal({
    super.key,
    required this.order,
    required this.products,
    this.isReplace = false,
    required this.onConfirm,
  });

  @override
  State<ReturnOrderModal> createState() => _ReturnOrderModalState();
}

class _ReturnOrderModalState extends State<ReturnOrderModal> {
  final Set<int> selectedProductIds = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isReplace ? 'Replace Items' : 'Return Items',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Select items you want to ${widget.isReplace ? 'replace' : 'return'}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    size: 24.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Products list
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: widget.products.length,
              separatorBuilder: (context, index) => Divider(height: 1.h),
              itemBuilder: (context, index) {
                final product = widget.products[index];
                final isSelected = selectedProductIds.contains(product.id);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedProductIds.add(product.id);
                      } else {
                        selectedProductIds.remove(product.id);
                      }
                    });
                  },
                  title: Text(
                    product.productName ?? 'Unknown Item',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Qty: ${product.quantity} • AED ${product.price.toStringAsFixed(2)} each',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  secondary: Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: product.productImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.network(
                              product.productImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.fastfood,
                                size: 24.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : Icon(
                            Icons.fastfood,
                            size: 24.sp,
                            color: Colors.grey[400],
                          ),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                );
              },
            ),
          ),
          
          // Info section
          Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: widget.isReplace ? Colors.blue[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: widget.isReplace ? Colors.blue[200]! : Colors.orange[200]!,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: widget.isReplace ? Colors.blue[700] : Colors.orange[700],
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    widget.isReplace
                        ? 'Replacement items will be delivered in your next order. Original charges will apply.'
                        : 'Refund will be processed within 5-7 business days after item pickup.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: widget.isReplace ? Colors.blue[900] : Colors.orange[900],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom actions
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${selectedProductIds.length} item${selectedProductIds.length != 1 ? 's' : ''} selected',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                ElevatedButton(
                  onPressed: selectedProductIds.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          widget.onConfirm(selectedProductIds.toList());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isReplace ? Colors.blue : Colors.orange,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: Text(
                    widget.isReplace ? 'Proceed to Replace' : 'Proceed to Return',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}