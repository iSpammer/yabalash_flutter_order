import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/cart_model.dart';

class TipSelectionWidget extends StatefulWidget {
  final List<TipOption> tipOptions;
  final double? selectedTip;
  final Function(double?) onTipSelected;

  const TipSelectionWidget({
    Key? key,
    required this.tipOptions,
    this.selectedTip,
    required this.onTipSelected,
  }) : super(key: key);

  @override
  State<TipSelectionWidget> createState() => _TipSelectionWidgetState();
}

class _TipSelectionWidgetState extends State<TipSelectionWidget> {
  bool _showCustomTip = false;
  final _customTipController = TextEditingController();
  final currencyFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

  @override
  void dispose() {
    _customTipController.dispose();
    super.dispose();
  }

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
            'Do you want to give a tip?',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),

          // Tip options
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              ...widget.tipOptions.map((tipOption) {
                final isSelected = widget.selectedTip == tipOption.value;
                return InkWell(
                  onTap: () {
                    widget.onTipSelected(isSelected ? null : tipOption.value);
                    setState(() {
                      _showCustomTip = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          currencyFormat.format(tipOption.value),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          tipOption.label,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isSelected ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              // Custom tip button
              InkWell(
                onTap: () {
                  setState(() {
                    _showCustomTip = !_showCustomTip;
                  });
                  if (_showCustomTip) {
                    widget.onTipSelected(null);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: _showCustomTip
                        ? Theme.of(context).primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: _showCustomTip
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _showCustomTip ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Custom tip input
          if (_showCustomTip)
            Column(
              children: [
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customTipController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Enter custom amount',
                          prefixText: 'AED ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                        ),
                        onChanged: (value) {
                          final amount = double.tryParse(value);
                          widget.onTipSelected(amount);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}