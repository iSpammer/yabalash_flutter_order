import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../restaurants/models/product_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/html_utils.dart';

class EnhancedProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showVendorName;
  final bool showFullDescription;

  const EnhancedProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.showVendorName = true,
    this.showFullDescription = false,
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              _buildProductImage(),
              SizedBox(width: 12.w),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductTitle(),
                    if (showVendorName) _buildVendorName(),
                    _buildRatingSection(context),
                    SizedBox(height: 8.h),
                    _buildPriceSection(context),
                    if (product.description != null &&
                        product.description!.isNotEmpty)
                      _buildDescription(),
                    SizedBox(height: 8.h),
                    _buildAddToCartSection(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final imageUrl =
        ImageUtils.buildImageUrl(product.thumbImage ?? product.image);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: SizedBox(
        width: 80.w,
        height: 80.w,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
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
              )
            : Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.fastfood,
                  size: 40.sp,
                  color: Colors.grey[600],
                ),
              ),
      ),
    );
  }

  Widget _buildProductTitle() {
    return Row(
      children: [
        // Veg/Non-veg indicator placeholder
        // TODO: Add veg/non-veg indicator when available in API
        Expanded(
          child: Text(
            product.name,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildVendorName() {
    // Extract vendor name from product data
    // This could come from product.vendorId lookup or directly from API
    final vendorName = _getVendorName();

    if (vendorName == null || vendorName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Text(
        vendorName,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    if (product.rating == null || product.rating! <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Wrap(
        spacing: 6.w,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          RatingBarIndicator(
            rating: product.rating!,
            itemBuilder: (context, index) => Icon(
              Icons.star,
              color: Colors.amber,
            ),
            itemCount: 5,
            itemSize: 14.sp,
          ),
          Text(
            product.rating!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (product.reviewCount != null && product.reviewCount! > 0) ...[
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
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 4.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Current price
        Text(
          'AED ${product.price.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).primaryColor,
          ),
        ),

        // Original price (if discounted)
        if (product.compareAtPrice != null &&
            product.compareAtPrice! > product.price) ...[
          Text(
            'AED ${product.compareAtPrice!.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              '${(((product.compareAtPrice! - product.price) / product.compareAtPrice!) * 100).round()}% OFF',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescription() {
    final description = HtmlUtils.safeExtractText(product.description);

    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 13.sp,
          color: Colors.grey[600],
          height: 1.3,
        ),
        maxLines: showFullDescription ? null : 2,
        overflow: showFullDescription ? null : TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAddToCartSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Stock status
        if (!product.isInStock)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Text(
              'OUT OF STOCK',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          const SizedBox.shrink(),

        // Add to Cart Button or Quantity Selector
        if (product.isInStock)
          _buildCartButton(context)
        else
          const SizedBox.shrink(),
      ],
    );
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
                    padding: EdgeInsets.all(6.w),
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
                    padding: EdgeInsets.all(6.w),
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
          return ElevatedButton(
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

              if (product.hasVariants ||
                  (product.addons?.isNotEmpty ?? false)) {
                // For products with variants/addons, use callback or navigate to detail
                if (onAddToCart != null) {
                  onAddToCart!();
                } else if (onTap != null) {
                  onTap!();
                }
              } else {
                // For simple products, add directly to cart
                final success = await cartProvider.addToCart(
                  product: product,
                  quantity: 1,
                );

                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          cartProvider.errorMessage ?? 'Failed to add to cart'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 6.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
              minimumSize: Size(60.w, 32.h),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.hasVariants || (product.addons?.isNotEmpty ?? false)
                      ? 'SELECT'
                      : 'ADD',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (product.hasVariants ||
                    (product.addons?.isNotEmpty ?? false)) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.add, size: 14.sp),
                ],
              ],
            ),
          );
        }
      },
    );
  }

  // Helper method to get vendor name
  String? _getVendorName() {
    // This would typically come from the API response
    // For now, we'll try to extract it from available data
    // You may need to enhance this based on your API structure

    // Check if vendor information is available in the product model
    // This might come from a joined query or separate field

    // Placeholder implementation - you'll need to adapt this
    // based on your actual API response structure
    return 'Restaurantdd Name'; // TODO: Get actual vendor name from API
  }
}
