import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../../core/widgets/cart_loading_dialog.dart';
import '../../../core/widgets/custom_button.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/delivery_pickup_toggle.dart';
import '../../../core/utils/auth_helper.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          context.push('/product/${product.id}');
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              if ((product.image != null && product.image!.isNotEmpty) ||
                  (product.thumbImage != null &&
                      product.thumbImage!.isNotEmpty))
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: CachedNetworkImage(
                    imageUrl: (product.thumbImage != null &&
                            product.thumbImage!.isNotEmpty)
                        ? product.thumbImage!
                        : (product.image != null && product.image!.isNotEmpty)
                            ? product.image!
                            : 'https://via.placeholder.com/150',
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.fastfood,
                        size: 40.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),

              SizedBox(width: 12.w),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Veg/Non-veg indicator
                    Row(
                      children: [
                        // Veg/Non-veg indicator would go here
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    if (product.description != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Time-based availability indicator
                    if (product.isLimitedTime) ...[
                      SizedBox(height: 6.h),
                      _buildTimeAvailabilityIndicator(),
                    ],

                    SizedBox(height: 8.h),

                    // Price and Add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.displayPrice,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (product.compareAtPrice != null &&
                                  product.compareAtPrice! > product.price) ...[
                                Text(
                                  'AED ${product.compareAtPrice!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Add to Cart Button or Quantity Selector
                        if (product.isInStock)
                          _buildCartButton(context)
                        else
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Additional info (ratings, preparation time, etc.)
                    if (product.rating != null ||
                        product.preparationTime != null) ...[
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 4.h,
                        children: [
                          if (product.rating != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14.sp,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  product.rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                if (product.reviewCount != null) ...[
                                  Text(
                                    ' (${product.reviewCount})',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (product.preparationTime != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14.sp,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    product.preparationTime!,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeAvailabilityIndicator() {
    if (!product.isLimitedTime) {
      return const SizedBox.shrink();
    }

    // Check if product is currently available
    if (product.isCurrentlyAvailable) {
      // Show expiry time if available
      final timeUntilExpires = product.timeUntilExpires;
      if (timeUntilExpires != null) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: 12.sp,
                color: Colors.orange[700],
              ),
              SizedBox(width: 4.w),
              Text(
                'Available for ${_formatDuration(timeUntilExpires)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 12.sp,
                color: Colors.green[700],
              ),
              SizedBox(width: 4.w),
              Text(
                'Limited time offer',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Show when it will be available
      final timeUntilAvailable = product.timeUntilAvailable;
      if (timeUntilAvailable != null) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time,
                size: 12.sp,
                color: Colors.blue[700],
              ),
              SizedBox(width: 4.w),
              Text(
                'Available in ${_formatDuration(timeUntilAvailable)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cancel,
                size: 12.sp,
                color: Colors.red[700],
              ),
              SizedBox(width: 4.w),
              Text(
                'No longer available',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Widget _buildCartButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final quantity = cartProvider.getQuantityForProduct(product);

        if (quantity > 0) {
          // Show quantity selector
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minus button
                InkWell(
                  onTap: () async {
                    // Check if user is logged in
                    if (!AuthHelper.checkAuthAndShowPrompt(context,
                        message: 'Please login to modify your cart.')) {
                      return;
                    }

                    final currentQuantity =
                        cartProvider.getQuantityForProduct(product);
                    if (currentQuantity > 1) {
                      // Find the cart item to update
                      final cartItem = cartProvider.getCartItem(product.id,
                          variantId: product.selectedVariantId != null
                              ? int.tryParse(product.selectedVariantId!)
                              : null);
                      if (cartItem?.id != null) {
                        await cartProvider.updateQuantity(
                          cartProductId: cartItem!.id!,
                          quantity: currentQuantity - 1,
                        );
                      }
                    } else {
                      // Remove from cart
                      final cartItem = cartProvider.getCartItem(product.id,
                          variantId: product.selectedVariantId != null
                              ? int.tryParse(product.selectedVariantId!)
                              : null);
                      if (cartItem?.id != null) {
                        await cartProvider.removeFromCart(
                            cartProductId: cartItem!.id!);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(6.r),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    child: Icon(
                      Icons.remove,
                      size: 16.sp,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),

                // Quantity display
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    quantity.toString(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),

                // Plus button
                InkWell(
                  onTap: () async {
                    // Check if user is logged in
                    if (!AuthHelper.checkAuthAndShowPrompt(context,
                        message: 'Please login to modify your cart.')) {
                      return;
                    }

                    final currentQuantity =
                        cartProvider.getQuantityForProduct(product);
                    // Find the cart item to update
                    final cartItem = cartProvider.getCartItem(product.id,
                        variantId: product.selectedVariantId != null
                            ? int.tryParse(product.selectedVariantId!)
                            : null);
                    if (cartItem?.id != null) {
                      await cartProvider.updateQuantity(
                        cartProductId: cartItem!.id!,
                        quantity: currentQuantity + 1,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(6.r),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    child: Icon(
                      Icons.add,
                      size: 16.sp,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Show ADD button
          return SizedBox(
            height: 36.h,
            child: CustomButton(
              text: product.hasVariants || (product.addons?.isNotEmpty ?? false)
                  ? 'SELECT'
                  : 'ADD',
              size: ButtonSize.small,
              icon:
                  (product.hasVariants || (product.addons?.isNotEmpty ?? false))
                      ? Icon(Icons.add, size: 16.sp, color: Colors.white)
                      : null,
              onPressed: () async {
                // Check if product is active before adding
                if (!product.isActive) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This product is currently unavailable'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                // Check if user is logged in
                if (!AuthHelper.checkAuthAndShowPrompt(context,
                    message: 'Please login to add items to your cart.')) {
                  return;
                }

                if (product.hasVariants ||
                    (product.addons?.isNotEmpty ?? false)) {
                  // For products with variants/addons, navigate to detail page
                  context.push('/product/${product.id}');
                } else {
                  // Sync delivery mode from dashboard only if different
                  final dashboardProvider = context.read<DashboardProvider>();
                  if (dashboardProvider.deliveryMode !=
                      cartProvider.deliveryMode) {
                    cartProvider.setDeliveryMode(dashboardProvider.deliveryMode,
                        skipReload: true);
                  }

                  // For simple products, add directly to cart with explicit type
                  final success = await cartProvider.addToCart(
                    product: product,
                    quantity: 1,
                    type:
                        dashboardProvider.deliveryMode == DeliveryMode.delivery
                            ? 'delivery'
                            : 'takeaway',
                  );

                  if (context.mounted) {
                    if (success) {
                      // Force close any remaining dialogs before showing snackbar
                      CartLoadingDialog.hideForce(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(cartProvider.errorMessage ??
                              'Failed to add to cart'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          );
        }
      },
    );
  }
}
