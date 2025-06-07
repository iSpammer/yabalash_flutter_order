import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../../core/widgets/cart_loading_dialog.dart';

class ProductCardWithLoading extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onAddToCart;
  
  const ProductCardWithLoading({
    super.key,
    required this.product,
    this.onAddToCart,
  });

  @override
  State<ProductCardWithLoading> createState() => _ProductCardWithLoadingState();
}

class _ProductCardWithLoadingState extends State<ProductCardWithLoading> {
  bool _isAddingToCart = false;

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
          context.push('/product/${widget.product.id}');
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              if ((widget.product.image != null && widget.product.image!.isNotEmpty) || 
                  (widget.product.thumbImage != null && widget.product.thumbImage!.isNotEmpty))
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: CachedNetworkImage(
                    imageUrl: (widget.product.thumbImage != null && widget.product.thumbImage!.isNotEmpty) 
                        ? widget.product.thumbImage! 
                        : (widget.product.image != null && widget.product.image!.isNotEmpty) 
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
                            widget.product.name,
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
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.displayPrice,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.product.compareAtPrice != null && 
                                widget.product.compareAtPrice! > widget.product.price) ...[
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
                        
                        // Add to Cart Button or Quantity Selector
                        if (widget.product.isInStock)
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final quantity = cartProvider.getQuantityForProduct(widget.product);
        
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
                  onTap: _isAddingToCart ? null : () async {
                    setState(() {
                      _isAddingToCart = true;
                    });
                    
                    final currentQuantity = cartProvider.getQuantityForProduct(widget.product);
                    if (currentQuantity > 1) {
                      // Find the cart item to update
                      final cartItem = cartProvider.getCartItem(widget.product.id, variantId: widget.product.selectedVariantId != null ? int.tryParse(widget.product.selectedVariantId!) : null);
                      if (cartItem?.id != null) {
                        await cartProvider.updateQuantity(
                          cartProductId: cartItem!.id!,
                          quantity: currentQuantity - 1,
                        );
                      }
                    } else {
                      // Remove from cart
                      final cartItem = cartProvider.getCartItem(widget.product.id, variantId: widget.product.selectedVariantId != null ? int.tryParse(widget.product.selectedVariantId!) : null);
                      if (cartItem?.id != null) {
                        await cartProvider.removeFromCart(cartProductId: cartItem!.id!);
                      }
                    }
                    
                    setState(() {
                      _isAddingToCart = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(6.r),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    child: Icon(
                      Icons.remove,
                      size: 16.sp,
                      color: _isAddingToCart ? Colors.grey : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                
                // Quantity display
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: _isAddingToCart 
                    ? SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ),
                      )
                    : Text(
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
                  onTap: _isAddingToCart ? null : () async {
                    setState(() {
                      _isAddingToCart = true;
                    });
                    
                    final currentQuantity = cartProvider.getQuantityForProduct(widget.product);
                    // Find the cart item to update
                    final cartItem = cartProvider.getCartItem(widget.product.id, variantId: widget.product.selectedVariantId != null ? int.tryParse(widget.product.selectedVariantId!) : null);
                    if (cartItem?.id != null) {
                      await cartProvider.updateQuantity(
                        cartProductId: cartItem!.id!,
                        quantity: currentQuantity + 1,
                      );
                    }
                    
                    setState(() {
                      _isAddingToCart = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(6.r),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    child: Icon(
                      Icons.add,
                      size: 16.sp,
                      color: _isAddingToCart ? Colors.grey : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Show ADD button
          return ElevatedButton(
            onPressed: _isAddingToCart ? null : () async {
              // Check if product is active before adding
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
              
              if (widget.product.hasVariants || (widget.product.addons?.isNotEmpty ?? false)) {
                // For products with variants/addons, navigate to detail page
                context.push('/product/${widget.product.id}');
              } else {
                // Check vendor conflict before adding
                if (cartProvider.currentVendorId != null &&
                    cartProvider.currentVendorId != widget.product.vendorId) {
                  _showVendorConflictDialog(cartProvider);
                  return;
                }
                
                // Show loading dialog
                CartLoadingDialog.show(context);
                
                setState(() {
                  _isAddingToCart = true;
                });
                
                // For simple products, add directly to cart
                final success = await cartProvider.addToCart(
                  product: widget.product,
                  quantity: 1,
                );
                
                // Hide loading dialog
                if (mounted) {
                  CartLoadingDialog.hide(context);
                  setState(() {
                    _isAddingToCart = false;
                  });
                }
                
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.product.name} added to cart'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'View Cart',
                          textColor: Colors.white,
                          onPressed: () => context.go('/cart'),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(cartProvider.errorMessage ?? 'Failed to add to cart'),
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
                horizontal: 20.w,
                vertical: 8.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: _isAddingToCart 
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'ADD',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
          );
        }
      },
    );
  }

  void _showVendorConflictDialog(CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Different Restaurant'),
          content: const Text(
            'Your cart contains items from a different restaurant. You can only order from one restaurant at a time.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (cartProvider.currentVendorId != null) {
                  context.push('/restaurant/${cartProvider.currentVendorId}');
                }
              },
              child: const Text('Browse Current Restaurant'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                // Show loading dialog
                CartLoadingDialog.show(context, message: 'Clearing cart and adding item...');
                
                setState(() {
                  _isAddingToCart = true;
                });
                
                await cartProvider.clearCart();
                
                final success = await cartProvider.addToCart(
                  product: widget.product,
                  quantity: 1,
                );
                
                // Hide loading dialog
                if (mounted) {
                  CartLoadingDialog.hide(context);
                  setState(() {
                    _isAddingToCart = false;
                  });
                }
                
                if (!mounted) return;
                
                if (success) {
                  // Force close any remaining dialogs before showing snackbar
                  CartLoadingDialog.hideForce(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cart cleared and ${widget.product.name} added'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(cartProvider.errorMessage ?? 'Failed to add item to cart'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Clear Cart & Add'),
            ),
          ],
        );
      },
    );
  }
}