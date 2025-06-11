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
import '../widgets/deliverable_section.dart';
import '../widgets/animated_address_section.dart';
import '../widgets/vendor_closed_warning.dart';
import '../widgets/delivery_mode_indicator.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/delivery_pickup_toggle.dart';

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
      _syncDeliveryMode();
    });
  }

  Future<void> _loadData() async {
    if (!_isInitialized) {
      _isInitialized = true;
      final cartProvider = context.read<CartProvider>();
      await cartProvider.loadCart();
    }
  }
  
  void _syncDeliveryMode() {
    // Sync delivery mode from dashboard to cart
    final dashboardProvider = context.read<DashboardProvider>();
    final cartProvider = context.read<CartProvider>();
    
    // If dashboard has a different delivery mode, update cart and force reload
    if (dashboardProvider.deliveryMode != cartProvider.deliveryMode) {
      debugPrint('Cart screen: Syncing delivery mode from ${cartProvider.deliveryMode} to ${dashboardProvider.deliveryMode}');
      // Update the mode without reloading, then reload in _loadData with correct type
      cartProvider.setDeliveryMode(dashboardProvider.deliveryMode, skipReload: true);
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
                        // Delivery mode indicator (read-only)
                        DeliveryModeIndicator(
                          currentMode: cartProvider.deliveryMode,
                        ),

                        // Animated delivery address section
                        const AnimatedAddressSection(),

                        // Cart items by vendor
                        if (cartProvider.cartData != null)
                          ...cartProvider.cartData!.products.map((vendorCart) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Vendor header
                                if (vendorCart.vendor != null)
                                  _buildVendorHeader(vendorCart.vendor!),

                                // Delivery validation warning
                                DeliverableSection(
                                  vendorCart: vendorCart,
                                  isPickupMode: cartProvider.deliveryMode == DeliveryMode.pickup,
                                ),

                                // Vendor closed warning
                                VendorClosedWarning(
                                  vendorCart: vendorCart,
                                  isPickupMode: cartProvider.deliveryMode == DeliveryMode.pickup,
                                ),

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

                        // Add extra padding for transparent navigation bar
                        SizedBox(height: 120.h),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    final isPickupMode = cartProvider.deliveryMode == DeliveryMode.pickup;
    
    // Check if any vendor has delivery issues
    bool hasDeliveryIssues = false;
    if (!isPickupMode && cartProvider.cartData != null) {
      for (var vendor in cartProvider.cartData!.products) {
        if (vendor.isDeliverable == false) {
          hasDeliveryIssues = true;
          break;
        }
      }
    }
    
    // Check if any vendor is closed
    bool hasClosedVendors = false;
    bool canScheduleOrder = false;
    if (cartProvider.cartData != null) {
      for (var vendor in cartProvider.cartData!.products) {
        if (vendor.vendor?.isVendorClosed == 1 || vendor.vendor?.isVendorClosed == true) {
          hasClosedVendors = true;
          if (vendor.vendor?.closedStoreOrderScheduled == 1) {
            canScheduleOrder = true;
          }
          break;
        }
      }
    }
    
    // Check if schedule is required but not set
    bool needsSchedule = hasClosedVendors && canScheduleOrder && 
                        cartProvider.scheduleType == 'now';
    
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
                  : !isPickupMode && !hasAddress
                      ? 'Add Delivery Address'
                      : hasDeliveryIssues
                          ? 'Remove Undeliverable Items'
                      : hasClosedVendors && !canScheduleOrder
                          ? 'Vendor Not Available'
                      : needsSchedule
                          ? 'Schedule Order'
                      : cartProvider.selectedPaymentMethodId == null
                          ? 'Select Payment Method'
                          : 'Place Order',
              backgroundColor: hasDeliveryIssues || (hasClosedVendors && !canScheduleOrder) 
                  ? Colors.red 
                  : needsSchedule ? Colors.orange : null,
              onPressed: cartProvider.isLoading
                  ? null
                  : () {
                      if (!isLoggedIn) {
                        context.push('/login');
                      } else if (!isPickupMode && !hasAddress) {
                        context.push('/addresses/select');
                      } else if (hasDeliveryIssues) {
                        // Show error message for delivery issues
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'The specific items are not deliverable to this address. Please remove the items or change the address.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (hasClosedVendors && !canScheduleOrder) {
                        // Show error for closed vendor that doesn't accept scheduled orders
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vendor is not accepting orders right now.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (needsSchedule) {
                        // Show message to schedule the order
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please schedule your order for later as the vendor is currently closed.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        // Scroll to schedule section
                        // You might want to implement scrolling to the schedule widget
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