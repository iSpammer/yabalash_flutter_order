import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/product_variant_service.dart';
import '../../restaurants/models/product_model.dart';

class AddonSelectionDialog extends StatefulWidget {
  final ProductVariantDetails variantDetails;
  final ProductModel product;
  final Function(List<Map<String, dynamic>>) onAddonsSelected;

  const AddonSelectionDialog({
    Key? key,
    required this.variantDetails,
    required this.product,
    required this.onAddonsSelected,
  }) : super(key: key);

  static Future<List<Map<String, dynamic>>?> show({
    required BuildContext context,
    required ProductVariantDetails variantDetails,
    required ProductModel product,
  }) async {
    return showDialog<List<Map<String, dynamic>>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AddonSelectionDialog(
          variantDetails: variantDetails,
          product: product,
          onAddonsSelected: (addons) {
            Navigator.of(context).pop(addons);
          },
        );
      },
    );
  }

  @override
  State<AddonSelectionDialog> createState() => _AddonSelectionDialogState();
}

class _AddonSelectionDialogState extends State<AddonSelectionDialog> {
  final Map<int, Set<int>> selectedAddons = {};
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  void _toggleAddon(int addonSetId, int addonOptionId, double price) {
    setState(() {
      if (!selectedAddons.containsKey(addonSetId)) {
        selectedAddons[addonSetId] = {};
      }
      
      final addonSet = widget.variantDetails.addonSets.firstWhere(
        (set) => set.addonId == addonSetId,
      );
      
      if (selectedAddons[addonSetId]!.contains(addonOptionId)) {
        selectedAddons[addonSetId]!.remove(addonOptionId);
      } else {
        // Check max selection limit
        if (selectedAddons[addonSetId]!.length < addonSet.maxSelect) {
          selectedAddons[addonSetId]!.add(addonOptionId);
        } else if (addonSet.maxSelect == 1) {
          // For single selection, replace the current selection
          selectedAddons[addonSetId]!.clear();
          selectedAddons[addonSetId]!.add(addonOptionId);
        }
      }
      
      _calculateTotalPrice();
    });
  }

  void _calculateTotalPrice() {
    double addonTotal = 0.0;
    
    for (final addonSet in widget.variantDetails.addonSets) {
      if (selectedAddons.containsKey(addonSet.addonId)) {
        for (final optionId in selectedAddons[addonSet.addonId]!) {
          final option = addonSet.addonOptions.firstWhere(
            (opt) => opt.id == optionId,
          );
          addonTotal += option.price;
        }
      }
    }
    
    setState(() {
      totalPrice = widget.product.price + addonTotal;
    });
  }

  bool _canProceed() {
    // Check if all required addons are selected
    for (final addonSet in widget.variantDetails.addonSets) {
      final selectedCount = selectedAddons[addonSet.addonId]?.length ?? 0;
      if (selectedCount < addonSet.minSelect) {
        return false;
      }
    }
    return true;
  }

  List<Map<String, dynamic>> _getSelectedAddonsFormatted() {
    final List<Map<String, dynamic>> formatted = [];
    
    for (final entry in selectedAddons.entries) {
      for (final optionId in entry.value) {
        formatted.add({
          'id': entry.key,
          'option_id': optionId,
        });
      }
    }
    
    return formatted;
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
          maxWidth: 400.w,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Customize your order',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Addon List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: widget.variantDetails.addonSets.length,
                itemBuilder: (context, index) {
                  final addonSet = widget.variantDetails.addonSets[index];
                  final isRequired = addonSet.minSelect > 0;
                  final selectedCount = selectedAddons[addonSet.addonId]?.length ?? 0;
                  
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                addonSet.title,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isRequired)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  'Required',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (addonSet.maxSelect > 1)
                          Text(
                            'Select up to ${addonSet.maxSelect} (${selectedCount} selected)',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        SizedBox(height: 8.h),
                        ...addonSet.addonOptions.map((option) {
                          final isSelected = selectedAddons[addonSet.addonId]
                                  ?.contains(option.id) ?? false;
                          
                          return InkWell(
                            onTap: () => _toggleAddon(
                              addonSet.addonId,
                              option.id,
                              option.price,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              margin: EdgeInsets.only(bottom: 4.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20.w,
                                    height: 20.w,
                                    decoration: BoxDecoration(
                                      shape: addonSet.maxSelect == 1
                                          ? BoxShape.circle
                                          : BoxShape.rectangle,
                                      borderRadius: addonSet.maxSelect != 1
                                          ? BorderRadius.circular(4.r)
                                          : null,
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            size: 12.sp,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text(
                                      option.title,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (option.price > 0)
                                    Text(
                                      '+AED ${option.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        if (index < widget.variantDetails.addonSets.length - 1)
                          Divider(height: 16.h),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Bar
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'AED ${totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canProceed()
                          ? () => widget.onAddonsSelected(_getSelectedAddonsFormatted())
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
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