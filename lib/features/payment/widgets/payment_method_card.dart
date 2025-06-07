import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/payment_method_model.dart';

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodCard({
    Key? key,
    required this.paymentMethod,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  IconData _getPaymentIcon() {
    final title = paymentMethod.title.toLowerCase();
    final code = paymentMethod.code?.toLowerCase() ?? '';
    
    if (title.contains('cash') || code.contains('cod')) {
      return Icons.money;
    } else if (title.contains('card') || code.contains('stripe')) {
      return Icons.credit_card;
    } else if (title.contains('wallet')) {
      return Icons.account_balance_wallet;
    } else if (title.contains('paypal')) {
      return Icons.payment;
    } else {
      return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getPaymentIcon(),
                size: 24.sp,
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[600],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paymentMethod.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Colors.black87,
                      ),
                    ),
                    if (paymentMethod.isOffSite)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          'Redirects to payment gateway',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Radio<int>(
                value: paymentMethod.id,
                groupValue: isSelected ? paymentMethod.id : null,
                onChanged: (_) => onTap(),
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}