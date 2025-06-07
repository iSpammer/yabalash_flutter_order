import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/order_model.dart';

class OrderSummaryCard extends StatelessWidget {
  final OrderModel order;

  const OrderSummaryCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 20.sp,
                color: const Color(0xFF2196F3),
              ),
              SizedBox(width: 8.w),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Order Number
          _buildInfoRow(
            'Order ID',
            '#${order.orderNumber}',
            Icons.tag,
            Colors.orange,
          ),
          
          // Order Date
          _buildInfoRow(
            'Order Date',
            _formatDate(order.createdAt ?? ''),
            Icons.calendar_today,
            Colors.blue,
          ),
          
          // Payment Method
          _buildInfoRow(
            'Payment',
            _getPaymentMethodDisplay(order),
            Icons.payment,
            Colors.green,
          ),
          
          // Order Type
          _buildInfoRow(
            'Order Type',
            order.luxuryOptionName ?? 'Delivery',
            Icons.local_shipping,
            Colors.purple,
          ),
          
          // Schedule Info
          if (order.scheduledDateTime != null)
            _buildInfoRow(
              'Scheduled',
              _formatScheduleTime(order.scheduledDateTime!),
              Icons.schedule,
              Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              size: 16.sp,
              color: color,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatScheduleTime(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = date.difference(now);
      
      if (difference.inDays > 0) {
        return 'In ${difference.inDays} days';
      } else if (difference.inHours > 0) {
        return 'In ${difference.inHours} hours';
      } else {
        return _formatDate(dateString);
      }
    } catch (e) {
      return dateString;
    }
  }

  String _getPaymentMethodDisplay(OrderModel order) {
    // First check the payment method string
    if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty) {
      // Check if it's a numeric ID
      final paymentId = int.tryParse(order.paymentMethod!);
      if (paymentId != null) {
        return _getPaymentMethodFromId(paymentId);
      }
      return order.paymentMethod!;
    }
    // Then check payment option
    if (order.paymentOption != null) {
      return _getPaymentMethodFromOption(order.paymentOption!);
    }
    return 'N/A';
  }
  
  String _getPaymentMethodFromId(int id) {
    switch (id) {
      case 1:
        return 'Cash on Delivery';
      case 2:
        return 'Credit/Debit Card';
      case 3:
        return 'Online Payment';
      default:
        return 'Payment Method $id';
    }
  }

  String _getPaymentMethodFromOption(PaymentOptionModel paymentOption) {
    // Map payment option IDs to display names
    switch (paymentOption.id) {
      case 1:
        return 'Cash on Delivery';
      case 2:
        return 'Credit/Debit Card';
      case 3:
        return 'Online Payment';
      default:
        return paymentOption.title;
    }
  }
}