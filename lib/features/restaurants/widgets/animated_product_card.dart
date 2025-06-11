import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../../core/widgets/cart_loading_dialog.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/delivery_pickup_toggle.dart';

class AnimatedProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onAddToCart;

  const AnimatedProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
  });

  @override
  State<AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        _controller.reverse();
        context.push('/product/${widget.product.id}');
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              margin: EdgeInsets.only(bottom: 12.h),
              elevation: _isPressed ? 1 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: child,
            ),
          );
        },
        child: InkWell(
          onTap: null, // Handled by GestureDetector
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with Hero animation
                if ((widget.product.image != null &&
                        widget.product.image!.isNotEmpty) ||
                    (widget.product.thumbImage != null &&
                        widget.product.thumbImage!.isNotEmpty))
                  Hero(
                    tag: 'product_image_${widget.product.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: CachedNetworkImage(
                        imageUrl: (widget.product.thumbImage != null &&
                                widget.product.thumbImage!.isNotEmpty)
                            ? widget.product.thumbImage!
                            : (widget.product.image != null &&
                                    widget.product.image!.isNotEmpty)
                                ? widget.product.image!
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
                  ),

                SizedBox(width: 12.w),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name with fade animation
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: _isPressed
                              ? Theme.of(context).primaryColor
                              : Colors.black87,
                        ),
                        child: Text(
                          widget.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      if (widget.product.description != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          widget.product.description!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: 8.h),

                      // Price and Add button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price with animated color
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _isPressed
                                      ? Theme.of(context).primaryColor
                                      : Colors.black87,
                                ),
                                child: Text(widget.product.displayPrice),
                              ),
                              if (widget.product.compareAtPrice != null &&
                                  widget.product.compareAtPrice! >
                                      widget.product.price) ...[
                                Text(
                                  'AED ${widget.product.compareAtPrice!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Add to Cart Button with animation
                          if (widget.product.isInStock)
                            _buildAnimatedCartButton(context)
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

                      // Additional info
                      if (widget.product.rating != null ||
                          widget.product.preparationTime != null) ...[
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            if (widget.product.rating != null) ...[
                              Icon(
                                Icons.star,
                                size: 14.sp,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                widget.product.rating!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (widget.product.reviewCount != null) ...[
                                Text(
                                  ' (${widget.product.reviewCount})',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              SizedBox(width: 12.w),
                            ],
                            if (widget.product.preparationTime != null) ...[
                              Icon(
                                Icons.access_time,
                                size: 14.sp,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                widget.product.preparationTime!,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
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
      ),
    );
  }

  Widget _buildAnimatedCartButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final quantity = cartProvider.getQuantityForProduct(widget.product);

        if (quantity > 0) {
          // Show animated quantity selector
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
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
                // Minus button with scale animation
                _buildQuantityButton(
                  icon: Icons.remove,
                  onTap: () async {
                    final currentQuantity =
                        cartProvider.getQuantityForProduct(widget.product);
                    if (currentQuantity > 1) {
                      final cartItem = cartProvider.getCartItem(
                        widget.product.id,
                        variantId: widget.product.selectedVariantId != null
                            ? int.tryParse(widget.product.selectedVariantId!)
                            : null,
                      );
                      if (cartItem?.id != null) {
                        await cartProvider.updateQuantity(
                          cartProductId: cartItem!.id!,
                          quantity: currentQuantity - 1,
                        );
                      }
                    } else {
                      final cartItem = cartProvider.getCartItem(
                        widget.product.id,
                        variantId: widget.product.selectedVariantId != null
                            ? int.tryParse(widget.product.selectedVariantId!)
                            : null,
                      );
                      if (cartItem?.id != null) {
                        await cartProvider.removeFromCart(
                            cartProductId: cartItem!.id!);
                      }
                    }
                  },
                ),

                // Animated quantity display
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Container(
                    key: ValueKey(quantity),
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
                ),

                // Plus button with scale animation
                _buildQuantityButton(
                  icon: Icons.add,
                  onTap: () async {
                    final currentQuantity =
                        cartProvider.getQuantityForProduct(widget.product);
                    final cartItem = cartProvider.getCartItem(
                      widget.product.id,
                      variantId: widget.product.selectedVariantId != null
                          ? int.tryParse(widget.product.selectedVariantId!)
                          : null,
                    );
                    if (cartItem?.id != null) {
                      await cartProvider.updateQuantity(
                        cartProductId: cartItem!.id!,
                        quantity: currentQuantity + 1,
                      );
                    }
                  },
                ),
              ],
            ),
          );
        } else {
          // Show animated ADD button
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: () async {
                if (!widget.product.isActive) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This product is currently unavailable'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                if (widget.product.hasVariants ||
                    (widget.product.addons?.isNotEmpty ?? false)) {
                  context.push('/product/${widget.product.id}');
                } else {
                  // Sync delivery mode
                  final dashboardProvider = context.read<DashboardProvider>();
                  if (dashboardProvider.deliveryMode !=
                      cartProvider.deliveryMode) {
                    cartProvider.setDeliveryMode(dashboardProvider.deliveryMode,
                        skipReload: true);
                  }

                  final success = await cartProvider.addToCart(
                    product: widget.product,
                    quantity: 1,
                    type:
                        dashboardProvider.deliveryMode == DeliveryMode.delivery
                            ? 'delivery'
                            : 'takeaway',
                  );

                  if (context.mounted) {
                    if (success) {
                      CartLoadingDialog.hideForce(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${widget.product.name} added to cart'),
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
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.product.hasVariants ||
                            (widget.product.addons?.isNotEmpty ?? false)
                        ? 'SELECT'
                        : 'ADD',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  if (widget.product.hasVariants ||
                      (widget.product.addons?.isNotEmpty ?? false))
                    Icon(Icons.add, size: 16.sp),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(8.w),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: Icon(
            icon,
            key: ValueKey(icon),
            size: 16.sp,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
