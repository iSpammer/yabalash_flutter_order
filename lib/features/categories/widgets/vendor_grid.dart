import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../restaurants/models/restaurant_model.dart';
import '../../restaurants/widgets/restaurant_card_v2.dart';

class VendorGrid extends StatefulWidget {
  final List<RestaurantModel> vendors;
  final bool isLoading;
  final ScrollController? scrollController;
  final VoidCallback? onLoadMore;

  const VendorGrid({
    super.key,
    required this.vendors,
    this.isLoading = false,
    this.scrollController,
    this.onLoadMore,
  });

  @override
  State<VendorGrid> createState() => _VendorGridState();
}

class _VendorGridState extends State<VendorGrid> {
  bool isGridView = true; // Default to grid view

  @override
  Widget build(BuildContext context) {
    if (widget.vendors.isEmpty && !widget.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store_outlined,
                size: 64.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16.h),
              Text(
                'No vendors found',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Try adjusting your filters or check back later.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // View toggle
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'View:',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleButton(
                      icon: Icons.view_agenda,
                      isSelected: !isGridView,
                      onTap: () => setState(() => isGridView = false),
                    ),
                    _buildViewToggleButton(
                      icon: Icons.grid_view,
                      isSelected: isGridView,
                      onTap: () => setState(() => isGridView = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Vendor list/grid
        Expanded(
          child: isGridView ? _buildGridView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(
          icon,
          size: 20.sp,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: widget.vendors.length + (widget.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.vendors.length) {
          return Center(child: CircularProgressIndicator());
        }
        
        final vendor = widget.vendors[index];
        return EnhancedVendorCard(
          restaurant: vendor,
          onTap: () => context.push('/restaurant/${vendor.id}'),
          isGridView: true,
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      itemCount: widget.vendors.length + (widget.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.vendors.length) {
          return Padding(
            padding: EdgeInsets.all(16.w),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        final vendor = widget.vendors[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: RestaurantCardV2(
            restaurant: vendor,
            isHorizontal: true,
            onTap: () => context.push('/restaurant/${vendor.id}'),
          ),
        );
      },
    );
  }
}

// Enhanced vendor card that shows description
class EnhancedVendorCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback? onTap;
  final bool isGridView;

  const EnhancedVendorCard({
    super.key,
    required this.restaurant,
    this.onTap,
    this.isGridView = true,
  });

  bool get isRestaurantClosed => !(restaurant.isOpen ?? true);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isRestaurantClosed ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  _buildCardImage(),
                  if (isRestaurantClosed) _buildClosedOverlay(),
                ],
              ),
            ),
            
            // Content section
            Flexible(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant name
                    Text(
                      restaurant.name ?? 'Restaurant',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: isRestaurantClosed ? Colors.grey : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Description if available
                    if (restaurant.description != null && 
                        restaurant.description!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        restaurant.description!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isRestaurantClosed 
                              ? Colors.grey[400] 
                              : Colors.grey[600],
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const Spacer(),
                    
                    // Rating if available
                    if (restaurant.rating != null && restaurant.rating! > 0) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.orange,
                            size: 12.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            restaurant.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isRestaurantClosed 
                                  ? Colors.grey[400] 
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                    ],
                    
                    // Bottom info
                    _buildBottomInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage() {
    String? imageUrl = restaurant.banner ?? restaurant.image ?? restaurant.logo;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          child: CachedNetworkImage(
            imageUrl: imageUrl ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[100]!, Colors.grey[200]!],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.grey[400]),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange[100]!,
                    Colors.orange[200]!,
                  ],
                ),
              ),
              child: Icon(
                Icons.restaurant,
                color: Colors.orange[400],
                size: 40.sp,
              ),
            ),
          ),
        ),
        
        // Promo badge
        if (restaurant.promoDiscount != null && 
            restaurant.promoDiscount!.isNotEmpty)
          Positioned(
            top: 8.h,
            left: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[400]!, Colors.pink[500]!],
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
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
                    size: 10.sp,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    restaurant.promoDiscount!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Open/Closed status
        if (restaurant.isOpen != null)
          Positioned(
            top: 8.h,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: restaurant.isOpen! 
                    ? Colors.green[500] 
                    : Colors.red[500],
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: (restaurant.isOpen! ? Colors.green : Colors.red)
                        .withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                restaurant.isOpen! ? 'OPEN' : 'CLOSED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildClosedOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              color: Colors.white,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              'CLOSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (restaurant.formattedDeliveryTime != null) ...[
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 11.sp,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 2.w),
                Flexible(
                  child: Text(
                    restaurant.formattedDeliveryTime!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (restaurant.deliveryFee != null) ...[
          if (restaurant.formattedDeliveryTime != null) 
            SizedBox(width: 4.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: restaurant.deliveryFee == 0 
                  ? Colors.green[50] 
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              restaurant.deliveryFee == 0 
                  ? 'Free' 
                  : 'AED ${restaurant.deliveryFee!.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 9.sp,
                color: restaurant.deliveryFee == 0 
                    ? Colors.green[700] 
                    : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}