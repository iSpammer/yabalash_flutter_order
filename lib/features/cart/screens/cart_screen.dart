import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/address_provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart_model.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/promo_code_section.dart';
import '../widgets/tip_selection_widget.dart';
import '../widgets/schedule_order_widget.dart';
import '../widgets/empty_cart_widget.dart';
import '../widgets/cart_summary_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!_isInitialized) {
      _isInitialized = true;
      final cartProvider = context.read<CartProvider>();
      await cartProvider.loadCart();
    }
  }

  Future<void> _onRefresh() async {
    final cartProvider = context.read<CartProvider>();
    await cartProvider.loadCart();
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text('Are you sure you want to clear all items from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final cartProvider = context.read<CartProvider>();
                await cartProvider.clearCart();
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              if (cartProvider.hasItems) {
                return TextButton(
                  onPressed: _showClearCartDialog,
                  child: Text(
                    'Clear Cart',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14.sp,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.isLoading && !_isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (cartProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cartProvider.errorMessage!,
                    style: TextStyle(fontSize: 16.sp),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  CustomButton(
                    text: 'Retry',
                    onPressed: _onRefresh,
                  ),
                ],
              ),
            );
          }

          if (!cartProvider.hasItems) {
            return const EmptyCartWidget();
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Delivery address section
                        _buildAddressSection(context),

                        // Cart items by vendor
                        if (cartProvider.cartData != null)
                          ...cartProvider.cartData!.products.map((vendorCart) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Vendor header
                                if (vendorCart.vendor != null)
                                  _buildVendorHeader(vendorCart.vendor!),

                                // Cart items
                                ...vendorCart.vendorProducts.map((item) {
                                  return CartItemCard(
                                    cartItem: item,
                                    onUpdateQuantity: (quantity) async {
                                      await cartProvider.updateQuantity(
                                        cartProductId: item.id!,
                                        quantity: quantity,
                                      );
                                    },
                                    onRemove: () async {
                                      await cartProvider.removeFromCart(
                                        cartProductId: item.id!,
                                      );
                                    },
                                  );
                                }).toList(),

                                // Promo code section
                                PromoCodeSection(
                                  vendorId: vendorCart.vendorId!,
                                  appliedCoupon: vendorCart.couponData,
                                  onApplyCode: (code) async {
                                    await cartProvider.applyPromoCode(
                                      vendorId: vendorCart.vendorId!,
                                      promoCode: code,
                                    );
                                  },
                                  onRemoveCode: () async {
                                    if (vendorCart.couponData?.couponId != null) {
                                      await cartProvider.removePromoCode(
                                        vendorId: vendorCart.vendorId!,
                                        couponId: vendorCart.couponData!.couponId!,
                                      );
                                    }
                                  },
                                ),

                                // Vendor total
                                if (vendorCart.payableAmount != null)
                                  _buildVendorTotal(vendorCart),

                                SizedBox(height: 16.h),
                              ],
                            );
                          }).toList(),

                        // Schedule order section
                        ScheduleOrderWidget(
                          scheduleType: cartProvider.scheduleType,
                          scheduledDateTime: cartProvider.scheduledDateTime,
                          onScheduleChanged: (type, dateTime) async {
                            await cartProvider.setScheduleType(
                              type,
                              scheduledDateTime: dateTime,
                            );
                          },
                        ),

                        // Tip selection
                        if (cartProvider.cartData?.tipOptions != null)
                          TipSelectionWidget(
                            tipOptions: cartProvider.cartData!.tipOptions!,
                            selectedTip: cartProvider.tipAmount,
                            onTipSelected: (amount) {
                              cartProvider.setTipAmount(amount);
                            },
                          ),

                        // Cart summary
                        if (cartProvider.cartData != null)
                          CartSummaryWidget(
                            cartData: cartProvider.cartData!,
                            tipAmount: cartProvider.tipAmount,
                          ),

                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                ),

                // Bottom checkout button
                _buildCheckoutButton(context, cartProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();
    final selectedAddress = addressProvider.selectedAddress;

    return InkWell(
      onTap: () {
        context.push('/addresses/select');
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 24.sp,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery at',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    selectedAddress != null
                        ? selectedAddress.fullAddress
                        : 'Add delivery address',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 24.sp,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorHeader(VendorInfo vendorInfo) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.grey[100],
      child: Row(
        children: [
          if (vendorInfo.logo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: CachedNetworkImage(
                imageUrl: ImageUtils.buildImageUrl(vendorInfo.logo) ?? '',
                width: 40.w,
                height: 40.w,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.store,
                    size: 20.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              vendorInfo.name ?? 'Restaurant',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorTotal(CartVendorItem vendorCart) {
    final currencyFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: [
          if (vendorCart.discountAmount != null && vendorCart.discountAmount! > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '- ${currencyFormat.format(vendorCart.discountAmount)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          if (vendorCart.deliverCharge != null && vendorCart.deliverCharge! > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Charge',
                  style: TextStyle(fontSize: 14.sp),
                ),
                Text(
                  currencyFormat.format(vendorCart.deliverCharge),
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                currencyFormat.format(vendorCart.payableAmount ?? 0),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(BuildContext context, CartProvider cartProvider) {
    final authProvider = context.watch<AuthProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final isLoggedIn = authProvider.user != null;
    final hasAddress = addressProvider.selectedAddress != null;
    final meetsMinimum = cartProvider.meetsMinimumOrder();
    final remainingAmount = cartProvider.getRemainingMinimumAmount();
    
    final currencyFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!meetsMinimum && remainingAmount > 0)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  'Add ${currencyFormat.format(remainingAmount)} more to reach minimum order',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.orange,
                  ),
                ),
              ),
            CustomButton(
              text: !isLoggedIn
                  ? 'Login to Continue'
                  : !hasAddress
                      ? 'Add Delivery Address'
                      : cartProvider.selectedPaymentMethodId == null
                          ? 'Select Payment Method'
                          : 'Place Order',
              onPressed: cartProvider.isLoading
                  ? null
                  : () {
                      if (!isLoggedIn) {
                        context.push('/login');
                      } else if (!hasAddress) {
                        context.push('/addresses/select');
                      } else if (!meetsMinimum) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Minimum order amount not met. Add ${currencyFormat.format(remainingAmount)} more.',
                            ),
                          ),
                        );
                      } else {
                        // Navigate to payment screen
                        context.push('/payment');
                      }
                    },
              isLoading: cartProvider.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}