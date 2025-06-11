import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/category_provider.dart';
import '../models/category_detail_model.dart';
import '../widgets/category_filters_widget.dart';
import '../widgets/enhanced_product_card.dart';
import '../widgets/vendor_grid.dart';
import '../../../core/widgets/custom_button.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/delivery_pickup_toggle.dart';
import '../../restaurants/widgets/restaurant_card_v2.dart';

class CategoryScreen extends StatefulWidget {
  final int categoryId;
  final String? categoryName;
  final String? categoryImage;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    this.categoryName,
    this.categoryImage,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late CategoryProvider _provider;
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<CategoryProvider>();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set delivery type from dashboard
      final dashboardProvider = context.read<DashboardProvider>();
      _provider.setDeliveryType(
          dashboardProvider.deliveryMode == DeliveryMode.delivery
              ? 'delivery'
              : 'takeaway');

      // Set location if available
      final (lat, lng) = dashboardProvider.locationCoordinates;
      if (lat != null && lng != null) {
        _provider.setLocation(
          latitude: lat,
          longitude: lng,
        );
      }

      _provider.loadCategoryDetails(widget.categoryId);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _provider.loadMoreProducts(widget.categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildCategoryAppBar(provider),
              _buildFiltersSection(provider),
              _buildProductsSection(provider),
              if (provider.isLoadingMoreProducts)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryAppBar(CategoryProvider provider) {
    final category = provider.categoryDetail;

    return SliverAppBar(
      expandedHeight: 250.h,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.share,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          onPressed: () => _shareCategory(provider),
        ),
        SizedBox(width: 8.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category?.name ?? widget.categoryName ?? 'Category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            if (category?.description != null &&
                category!.description!.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                category.description!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        titlePadding: EdgeInsets.only(left: 16.w, bottom: 16.h, right: 16.w),
        background: _buildCategoryBanner(category),
      ),
    );
  }

  Widget _buildCategoryBanner(CategoryDetailModel? category) {
    // Use displayImage from API response, fallback to passed categoryImage
    final imageUrl = category?.displayImage ?? widget.categoryImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).primaryColor,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).primaryColor,
              child: Icon(
                Icons.category,
                color: Colors.white,
                size: 64.sp,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.category,
            color: Colors.white,
            size: 64.sp,
          ),
        ),
      );
    }
  }

  Widget _buildFiltersSection(CategoryProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          children: [
            Row(
              children: [
                // Filter button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    icon: Icon(
                      _showFilters ? Icons.filter_list_off : Icons.filter_list,
                      size: 20.sp,
                    ),
                    label: Text(
                      _showFilters ? 'Hide Filters' : 'Filters',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: BorderSide(
                        color: provider.hasFiltersApplied
                            ? Theme.of(context).primaryColor
                            : Colors.grey[400]!,
                      ),
                      foregroundColor: provider.hasFiltersApplied
                          ? Theme.of(context).primaryColor
                          : Colors.grey[700],
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Sort button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSortOptions(provider),
                    icon: Icon(Icons.sort, size: 20.sp),
                    label: Text(
                      provider.selectedSort.displayName,
                      style: TextStyle(fontSize: 14.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: BorderSide(color: Colors.grey[400]!),
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),

            // Applied filters display
            if (provider.hasFiltersApplied) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      provider.filtersDisplayText,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        provider.clearAllFilters(widget.categoryId),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Results count
            if (provider.totalProducts > 0) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      provider.isVendorCategory
                          ? '${provider.totalProducts} vendors found'
                          : '${provider.totalProducts} products found',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(CategoryProvider provider) {
    debugPrint(
        'Building products section - isVendorCategory: ${provider.isVendorCategory}, vendors: ${provider.vendors.length}, products: ${provider.products.length}');

    // Determine content type based on category type or actual data
    final hasVendors = provider.vendors.isNotEmpty;
    final hasProducts = provider.products.isNotEmpty;

    if (provider.isLoadingProducts &&
        provider.products.isEmpty &&
        provider.vendors.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text(
                'Loading items...',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.productsError != null &&
        provider.products.isEmpty &&
        provider.vendors.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  provider.isVendorCategory
                      ? 'Failed to load vendors'
                      : 'Failed to load products',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  provider.productsError!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                CustomButton(
                  text: 'Try Again',
                  onPressed: () =>
                      provider.loadProducts(widget.categoryId, refresh: true),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Handle both vendors and products based on what's available
    if (hasVendors && !hasProducts) {
      // Only vendors available
      return SliverFillRemaining(
        hasScrollBody: true,
        fillOverscroll: false,
        child: VendorGrid(
          vendors: provider.vendors,
          isLoading: provider.isLoadingMoreProducts,
          scrollController: ScrollController(),
          onLoadMore: () => provider.loadMoreProducts(widget.categoryId),
        ),
      );
    } else if (hasProducts && !hasVendors) {
      // Only products available - display as list
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < provider.products.length) {
              final product = provider.products[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                child: EnhancedProductCard(
                  product: product,
                  showVendorName: true,
                  onTap: () => context.push('/product/${product.id}'),
                ),
              );
            }
            return null;
          },
          childCount: provider.products.length,
        ),
      );
    } else if (hasVendors && hasProducts) {
      // Both vendors and products - show in sections
      return SliverList(
        delegate: SliverChildListDelegate([
          // Vendors section
          if (hasVendors) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Text(
                'Restaurants',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(
              height: 280.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: provider.vendors.length,
                itemBuilder: (context, index) {
                  final vendor = provider.vendors[index];
                  return Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: SizedBox(
                      width: 280.w,
                      child: RestaurantCardV2(
                        restaurant: vendor,
                        onTap: () => context.push('/restaurant/${vendor.id}'),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24.h),
          ],

          // Products section
          if (hasProducts) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Text(
                'Products',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            ...provider.products.map((product) => Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  child: EnhancedProductCard(
                    product: product,
                    showVendorName: true,
                    onTap: () => context.push('/product/${product.id}'),
                  ),
                )),
          ],
        ]),
      );
    }

    // No items found
    if (!hasVendors && !hasProducts) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  'No products found',
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
                if (provider.hasFiltersApplied) ...[
                  SizedBox(height: 24.h),
                  CustomButton(
                    text: 'Clear Filters',
                    onPressed: () =>
                        provider.clearAllFilters(widget.categoryId),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < provider.products.length) {
            final product = provider.products[index];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: EnhancedProductCard(
                product: product,
                showVendorName: true,
                onTap: () => context.push('/product/${product.id}'),
              ),
            );
          }
          return null;
        },
        childCount: provider.products.length,
      ),
    );
  }

  void _shareCategory(CategoryProvider provider) {
    final shareText = provider.getShareText();
    Share.share(shareText);
  }

  void _showSortOptions(CategoryProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            ...CategorySortOption.values.map((option) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  option.displayName,
                  style: TextStyle(fontSize: 16.sp),
                ),
                trailing: provider.selectedSort == option
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
                onTap: () {
                  provider.applySorting(widget.categoryId, option);
                  Navigator.pop(context);
                },
              );
            }),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

// Show filters widget in a modal
void showFiltersModal(
    BuildContext context, CategoryProvider provider, int categoryId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => CategoryFiltersWidget(
        provider: provider,
        categoryId: categoryId,
        scrollController: scrollController,
      ),
    ),
  );
}
