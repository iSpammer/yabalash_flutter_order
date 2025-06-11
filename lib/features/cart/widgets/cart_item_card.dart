import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/image_utils.dart';
import '../models/cart_model.dart';

class CartItemCard extends StatelessWidget {
  final CartProductItem cartItem;
  final Function(int) onUpdateQuantity;
  final VoidCallback onRemove;

  const CartItemCard({
    Key? key,
    required this.cartItem,
    required this.onUpdateQuantity,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = cartItem.product;
    final variant = cartItem.variants;
    final currencyFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

    if (product == null) {
      return const SizedBox.shrink();
    }

    // Get product image
    String? imageUrl;
    
    // First try to get image from cart image using the fullImageUrl getter
    if (cartItem.cartImg?.fullImageUrl != null) {
      imageUrl = cartItem.cartImg!.fullImageUrl;
      debugPrint('🛒 Cart image from fullImageUrl: $imageUrl');
    } else if (product.image != null) {
      imageUrl = ImageUtils.buildImageUrl(product.image!);
      debugPrint('🛒 Cart image from product.image: $imageUrl');
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: CachedNetworkImage(
              imageUrl: imageUrl ?? '',
              width: 80.w,
              height: 80.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.image_not_supported,
                  size: 40.sp,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  product.name ?? 'Product',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),

                // Variant info
                if (cartItem.variantOptions != null && cartItem.variantOptions!.isNotEmpty)
                  ...cartItem.variantOptions!.map((variantOption) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Text(
                        '${variantOption.title}: ${variantOption.option}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),

                // Addons
                if (cartItem.productAddons != null && cartItem.productAddons!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4.h),
                      Text(
                        'Extras:',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ...cartItem.productAddons!.map((addon) {
                        final addonPrice = (addon.price ?? 0) * (addon.multiplier ?? 1);
                        return Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Text(
                            '${addon.addonTitle}: ${addon.optionTitle} (+${currencyFormat.format(addonPrice)})',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                  ),

                SizedBox(height: 8.h),

                // Price and quantity controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Text(
                      currencyFormat.format(variant?.quantityPrice ?? 0),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),

                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              final newQuantity = (cartItem.quantity ?? 1) - 1;
                              if (newQuantity > 0) {
                                onUpdateQuantity(newQuantity);
                              } else {
                                onRemove();
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              child: Icon(
                                Icons.remove,
                                size: 20.sp,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              '${cartItem.quantity ?? 1}',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              final newQuantity = (cartItem.quantity ?? 1) + 1;
                              onUpdateQuantity(newQuantity);
                            },
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              child: Icon(
                                Icons.add,
                                size: 20.sp,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}