import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/restaurant_model.dart';

class RestaurantCardV2 extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback? onTap;
  final bool isHorizontal;

  const RestaurantCardV2({
    Key? key,
    required this.restaurant,
    this.onTap,
    this.isHorizontal = true,
  }) : super(key: key);

  bool get isRestaurantClosed => !(restaurant.isOpen ?? true);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isRestaurantClosed ? null : onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: isHorizontal ? _buildHorizontalCard(context) : _buildVerticalCard(context),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced image with gradient overlay
              Hero(
                tag: 'restaurant-${restaurant.id}-card',
                child: Container(
                  width: 110.w,
                  height: 110.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildRestaurantImage(width: 110.w, height: 110.w),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRestaurantInfo(context),
                    SizedBox(height: 10.h),
                    _buildMetaInfo(context),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isRestaurantClosed) _buildClosedOverlay(context),
      ],
    );
  }

  Widget _buildVerticalCard(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildRestaurantImage(width: double.infinity, height: 160.h),
                _buildPromoTag(),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRestaurantInfo(context),
                  SizedBox(height: 8.h),
                  _buildMetaInfo(context),
                ],
              ),
            ),
          ],
        ),
        if (isRestaurantClosed) _buildClosedOverlay(context),
      ],
    );
  }

  Widget _buildRestaurantImage({required double width, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Stack(
        children: [
          // Main banner image (full background)
          _buildBannerImage(width, height),
          
          // Logo overlay in bottom-left corner
          if (restaurant.logo != null && restaurant.logo!.isNotEmpty)
            _buildLogoOverlay(),
          
          // Promo code display in top-left corner
          if (restaurant.promoDiscount != null && restaurant.promoDiscount!.isNotEmpty)
            _buildPromoCodeBadge(),
          
          // Gradient overlay for better text visibility
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),
          
          // Closed overlay if restaurant is closed
          if (isRestaurantClosed)
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          
          // Availability badge in top-right corner
          Positioned(
            top: 8.h,
            right: 8.w,
            child: _buildAvailabilityBadge(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBannerImage(double width, double height) {
    // Prioritize banner for visual appeal, fall back to main image, then logo
    String? bannerUrl = restaurant.banner ?? restaurant.image ?? restaurant.logo;
    
    return CachedNetworkImage(
      imageUrl: bannerUrl ?? '',
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange[50]!,
              Colors.orange[100]!,
              Colors.orange[200]!,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              color: Colors.orange[400],
              size: 32.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              restaurant.name ?? 'Restaurant',
              style: TextStyle(
                color: Colors.orange[600],
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.blue[100]!,
              Colors.blue[200]!,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood,
              color: Colors.blue[400],
              size: 32.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              restaurant.name ?? 'Restaurant',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLogoOverlay() {
    return Positioned(
      bottom: 8.h,
      left: 8.w,
      child: Container(
        width: 45.w,
        height: 45.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: restaurant.logo!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.grey[100]!, Colors.grey[200]!],
                ),
              ),
              child: Icon(
                Icons.restaurant,
                color: Colors.grey[400],
                size: 20.sp,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.grey[100]!, Colors.grey[200]!],
                ),
              ),
              child: Icon(
                Icons.restaurant,
                color: Colors.grey[400],
                size: 20.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPromoCodeBadge() {
    return Positioned(
      top: 8.h,
      left: 8.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[400]!, Colors.pink[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_offer,
              color: Colors.white,
              size: 14.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              restaurant.promoDiscount!.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoTag() {
    // Show promo discount first, then tags
    String? promoText;
    Color promoColor = Colors.red;
    IconData promoIcon = Icons.local_offer;
    
    if (restaurant.promoDiscount != null && restaurant.promoDiscount!.isNotEmpty) {
      promoText = restaurant.promoDiscount!.toUpperCase();
      promoColor = Colors.red;
      promoIcon = Icons.local_offer;
    } else if (restaurant.tags != null && restaurant.tags!.isNotEmpty) {
      promoText = restaurant.tags!.first.toUpperCase();
      promoColor = Colors.purple;
      promoIcon = Icons.star;
    }
    
    if (promoText == null) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: 8.h,
      left: 8.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: promoColor == Colors.red 
                ? [Colors.red[400]!, Colors.pink[500]!]
                : [Colors.purple[400]!, Colors.indigo[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: promoColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              promoIcon,
              color: Colors.white,
              size: 12.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              promoText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name ?? 'Restaurant',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: isRestaurantClosed ? Colors.grey : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (restaurant.rating != null && restaurant.rating! > 0) ...[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getRatingColor(restaurant.rating!),
                                _getRatingColor(restaurant.rating!).withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: _getRatingColor(restaurant.rating!).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 14.sp,
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                restaurant.rating!.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (restaurant.reviewCount != null && restaurant.reviewCount! > 0) ...[
                                SizedBox(width: 4.w),
                                Text(
                                  '(${restaurant.reviewCount})',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Expanded(
                        child: Text(
                          _getCuisinesText(),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isRestaurantClosed ? Colors.grey[400] : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row: Delivery info with enhanced design
        Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              if (restaurant.formattedDistance != null) ...[
                _buildInfoChip(
                  icon: Icons.location_on_rounded,
                  text: restaurant.formattedDistance!,
                  iconColor: Colors.blue[600]!,
                  backgroundColor: Colors.blue[50]!,
                ),
                SizedBox(width: 8.w),
              ],
              if (restaurant.formattedDeliveryTime != null) ...[
                _buildInfoChip(
                  icon: Icons.access_time_rounded,
                  text: restaurant.formattedDeliveryTime!,
                  iconColor: Colors.orange[600]!,
                  backgroundColor: Colors.orange[50]!,
                ),
                SizedBox(width: 8.w),
              ],
              if (restaurant.minimumOrderAmount != null && restaurant.minimumOrderAmount! > 0) ...[
                _buildInfoChip(
                  icon: Icons.shopping_basket_rounded,
                  text: 'Min AED ${restaurant.minimumOrderAmount!.toStringAsFixed(0)}',
                  iconColor: Colors.purple[600]!,
                  backgroundColor: Colors.purple[50]!,
                ),
              ],
            ],
          ),
        ),
        
        // Delivery fee badge with enhanced design
        if (restaurant.deliveryFee != null) ...[
          Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: restaurant.deliveryFee == 0 
                    ? [Colors.green[400]!, Colors.green[600]!]
                    : [Colors.grey[100]!, Colors.grey[200]!],
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: restaurant.deliveryFee == 0 ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delivery_dining_rounded,
                  size: 16.sp,
                  color: restaurant.deliveryFee == 0 ? Colors.white : Colors.grey[700],
                ),
                SizedBox(width: 6.w),
                Text(
                  restaurant.deliveryFee == 0 
                      ? 'FREE DELIVERY' 
                      : 'AED ${restaurant.deliveryFee!.toStringAsFixed(0)} Delivery',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: restaurant.deliveryFee == 0 ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Special features row
        if (restaurant.promoDiscount != null || 
            restaurant.isPureVeg == true || 
            (restaurant.tags != null && restaurant.tags!.isNotEmpty)) ...[
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              if (restaurant.promoDiscount != null && restaurant.promoDiscount!.isNotEmpty)
                _buildFeatureBadge(
                  icon: Icons.local_offer_rounded,
                  text: restaurant.promoDiscount!.toUpperCase(),
                  gradient: [Colors.red[400]!, Colors.pink[500]!],
                ),
              if (restaurant.isPureVeg == true)
                _buildFeatureBadge(
                  icon: Icons.eco_rounded,
                  text: 'PURE VEG',
                  gradient: [Colors.green[400]!, Colors.green[600]!],
                ),
              if (restaurant.tags != null && restaurant.tags!.isNotEmpty)
                _buildFeatureBadge(
                  icon: Icons.star_rounded,
                  text: restaurant.tags!.first.toUpperCase(),
                  gradient: [Colors.purple[400]!, Colors.purple[600]!],
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required String text,
    required List<Color> gradient,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 12.sp,
          ),
          SizedBox(width: 3.w),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isRestaurantClosed ? Colors.grey[100] : backgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isRestaurantClosed ? Colors.grey[300]! : backgroundColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isRestaurantClosed ? Colors.grey[400] : iconColor,
            size: 14.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: isRestaurantClosed ? Colors.grey[400] : iconColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge() {
    if (restaurant.isOpen == null) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: restaurant.isOpen! 
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.red[400]!, Colors.red[600]!],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: (restaurant.isOpen! ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            restaurant.isOpen! ? 'OPEN' : 'CLOSED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[500]!, Colors.red[700]!],
                  ),
                  borderRadius: BorderRadius.circular(25.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'CURRENTLY CLOSED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Will open soon',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green[600]!;
    if (rating >= 4.0) return Colors.green[700]!;
    if (rating >= 3.5) return Colors.orange[600]!;
    if (rating >= 3.0) return Colors.orange[700]!;
    return Colors.red[600]!;
  }

  String _getCuisinesText() {
    if (restaurant.cuisines != null && restaurant.cuisines!.isNotEmpty) {
      return restaurant.cuisines!.take(2).join(', ');
    }
    return restaurant.description ?? 'Restaurant';
  }

  String _getServiceTypes() {
    List<String> services = [];
    if (restaurant.isPickupAvailable == true) services.add('Pickup');
    if (restaurant.isDeliveryAvailable == true) services.add('Delivery');
    return services.isNotEmpty ? services.join(' • ') : 'Available';
  }
  
  Widget _buildPositionedBadges() {
    return Stack(
      children: [
        // Promo discount in top-left
        if (restaurant.promoDiscount != null && restaurant.promoDiscount!.isNotEmpty)
          Positioned(
            top: 8.h,
            left: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[400]!, Colors.pink[500]!],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer,
                    color: Colors.white,
                    size: 12.sp,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    restaurant.promoDiscount!.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Availability badge in top-right
        Positioned(
          top: 8.h,
          right: 8.w,
          child: _buildAvailabilityBadge(),
        ),
        
        // Additional tags below promo (if space allows)
        if (restaurant.tags != null && restaurant.tags!.isNotEmpty)
          Positioned(
            top: restaurant.promoDiscount != null ? 35.h : 8.h,
            left: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.purple[500],
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                restaurant.tags!.first.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildVerticalPositionedBadges() {
    return Stack(
      children: [
        // Promo discount in top-left
        if (restaurant.promoDiscount != null && restaurant.promoDiscount!.isNotEmpty)
          Positioned(
            top: 8.h,
            left: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[400]!, Colors.pink[500]!],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    restaurant.promoDiscount!.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Availability badge in top-right
        Positioned(
          top: 8.h,
          right: 8.w,
          child: _buildAvailabilityBadge(),
        ),
        
        // Logo overlay in bottom-left
        if (restaurant.logo != null && restaurant.logo!.isNotEmpty)
          _buildLogoOverlay(),
      ],
    );
  }
  
  Widget _buildCardBannerBackground() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Stack(
        children: [
          // Full card banner background
          _buildBannerImage(double.infinity, double.infinity),
          
          // Gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.95),
                ],
              ),
            ),
          ),
          
          // Subtle pattern overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  Colors.blue.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRestaurantLogo({required double width, required double height}) {
    String? logoUrl = restaurant.logo ?? restaurant.image;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: CachedNetworkImage(
          imageUrl: logoUrl ?? '',
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[100]!, Colors.grey[200]!],
              ),
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: Colors.grey[400],
              size: 24.sp,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[100]!, Colors.orange[200]!],
              ),
            ),
            child: Icon(
              Icons.fastfood,
              color: Colors.orange[400],
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }
}