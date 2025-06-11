import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../../profile/providers/address_provider.dart';
import '../../dashboard/widgets/delivery_pickup_toggle.dart';

class AnimatedAddressSection extends StatefulWidget {
  const AnimatedAddressSection({Key? key}) : super(key: key);

  @override
  State<AnimatedAddressSection> createState() => _AnimatedAddressSectionState();
}

class _AnimatedAddressSectionState extends State<AnimatedAddressSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();
    final cartProvider = context.watch<CartProvider>();
    final selectedAddress = addressProvider.selectedAddress;
    final isPickupMode = cartProvider.deliveryMode == DeliveryMode.pickup;

    // Trigger animation when mode changes
    if (_controller.isCompleted) {
      _controller.reverse().then((_) {
        if (mounted) {
          _controller.forward();
        }
      });
    }

    if (isPickupMode) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildPickupSection(),
          ),
        ),
      );
    }

    // Check if any items are not deliverable
    bool hasDeliveryIssues = false;
    if (cartProvider.cartData != null && selectedAddress != null) {
      for (var vendor in cartProvider.cartData!.products) {
        if (vendor.isDeliverable == false) {
          hasDeliveryIssues = true;
          break;
        }
      }
    }

    return Column(
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildDeliverySection(
                context,
                selectedAddress,
                hasDeliveryIssues,
              ),
            ),
          ),
        ),
        if (selectedAddress == null && !isPickupMode)
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildAddressWarning(),
            ),
          ),
      ],
    );
  }

  Widget _buildPickupSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.blue[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'location_icon',
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.store,
                size: 24.sp,
                color: Colors.blue[700],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup Order',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  'You will collect this order from the restaurant',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(
    BuildContext context,
    dynamic selectedAddress,
    bool hasDeliveryIssues,
  ) {
    return InkWell(
      onTap: () {
        context.push('/addresses/select');
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: hasDeliveryIssues
              ? Colors.red[50]
              : selectedAddress != null
                  ? Colors.green[50]
                  : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: hasDeliveryIssues
                  ? Colors.red[200]!
                  : selectedAddress != null
                      ? Colors.green[200]!
                      : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'location_icon',
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: hasDeliveryIssues
                      ? Colors.red[100]
                      : selectedAddress != null
                          ? Colors.green[100]
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 24.sp,
                  color: hasDeliveryIssues
                      ? Colors.red[700]
                      : selectedAddress != null
                          ? Colors.green[700]
                          : Theme.of(context).primaryColor,
                ),
              ),
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
                      color: hasDeliveryIssues
                          ? Colors.red[700]
                          : Colors.grey[600],
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
                      color: hasDeliveryIssues ? Colors.red[700] : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasDeliveryIssues && selectedAddress != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Some items cannot be delivered to this address',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedRotation(
              turns: 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.chevron_right,
                size: 24.sp,
                color: hasDeliveryIssues
                    ? Colors.red[700]
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressWarning() {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20.sp,
            color: Colors.orange[700],
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Please add a delivery address to continue',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}