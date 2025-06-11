import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/restaurant_info_header.dart';
import '../widgets/product_card.dart';
import '../../cart/providers/cart_provider.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final int restaurantId;
  
  const RestaurantDetailScreen({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> 
    with TickerProviderStateMixin {
  TabController? _tabController;
  final ScrollController _scrollController = ScrollController();
  int _currentRestaurantId = -1;

  @override
  void initState() {
    super.initState();
    debugPrint('RestaurantDetailScreen initState for restaurant ${widget.restaurantId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRestaurantDetails();
    });
  }

  @override
  void didUpdateWidget(RestaurantDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If restaurant ID changed, reload the data
    if (oldWidget.restaurantId != widget.restaurantId) {
      _loadRestaurantDetails();
    }
  }

  @override
  void dispose() {
    debugPrint('RestaurantDetailScreen dispose for restaurant ${widget.restaurantId}');
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showClosedRestaurantDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Restaurant Closed'),
        content: const Text('This restaurant is currently unavailable. Please check back later or browse other restaurants.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _initializeTabController(int categoriesLength) {
    if (categoriesLength > 0 && _tabController == null) {
      debugPrint('Initializing TabController with $categoriesLength categories');
      
      _tabController = TabController(
        length: categoriesLength,
        vsync: this,
      );
    } else if (categoriesLength > 0 && _tabController != null) {
      // Only recreate if length changed
      if (_tabController!.length != categoriesLength) {
        debugPrint('Recreating TabController: old length ${_tabController!.length}, new length $categoriesLength');
        _tabController?.dispose();
        _tabController = TabController(
          length: categoriesLength,
          vsync: this,
        );
      }
    }
  }

  Future<void> _loadRestaurantDetails() async {
    final provider = context.read<RestaurantProvider>();
    
    debugPrint('_loadRestaurantDetails called for restaurant ${widget.restaurantId}, current: $_currentRestaurantId');
    
    // Only reload if this is a different restaurant
    if (_currentRestaurantId != widget.restaurantId) {
      debugPrint('Loading new restaurant ${widget.restaurantId}');
      _currentRestaurantId = widget.restaurantId;
      
      // Dispose existing tab controller when switching restaurants
      if (_tabController != null) {
        debugPrint('Disposing existing TabController');
        _tabController?.dispose();
        _tabController = null;
      }
      
      await provider.loadRestaurantDetails(widget.restaurantId);
      
      // Check if restaurant is closed and show dialog
      if (mounted && provider.currentRestaurant != null && !(provider.currentRestaurant!.isOpen ?? true)) {
        _showClosedRestaurantDialog();
      }
      
      // Initialize TabController after restaurant data is loaded
      if (mounted && provider.menuCategories.isNotEmpty) {
        debugPrint('Initializing TabController after data load');
        _initializeTabController(provider.menuCategories.length);
        setState(() {});
      }
    } else {
      debugPrint('Same restaurant, skipping reload');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.currentRestaurant == null) {
            return _buildLoadingState();
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading restaurant',
                    style: TextStyle(fontSize: 18.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    provider.errorMessage!,
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                  SizedBox(height: 16.h),
                  CustomButton(
                    text: 'Retry',
                    onPressed: _loadRestaurantDetails,
                    outlined: true,
                  ),
                ],
              ),
            );
          }

          final restaurant = provider.currentRestaurant;
          if (restaurant == null) return const SizedBox();

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Restaurant Header
                  SliverToBoxAdapter(
                    child: RestaurantInfoHeader(restaurant: restaurant),
                  ),
                  
                  // Menu Categories Tabs
                  if (provider.menuCategories.isNotEmpty && _tabController != null) ...[
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverTabBarDelegate(
                        TabBar(
                          controller: _tabController!,
                          isScrollable: true,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Theme.of(context).primaryColor,
                          tabs: provider.menuCategories.map((category) {
                            return Tab(text: category.name);
                          }).toList(),
                        ),
                      ),
                    ),
                    
                    // Products List
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController!,
                        children: provider.menuCategories.map((category) {
                          final products = provider.getProductsByCategory(category.id);
                          
                          if (products.isEmpty) {
                            return Center(
                              child: Text(
                                'No items available in this category',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            padding: EdgeInsets.all(16.w),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return ProductCard(
                                product: products[index],
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ] else ...[
                    SliverFillRemaining(
                      child: Center(
                        child: provider.isLoading
                            ? const CircularProgressIndicator()
                            : provider.menuCategories.isNotEmpty && _tabController == null
                                ? const CircularProgressIndicator() // Still initializing tabs
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'No menu items available',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (provider.errorMessage != null) ...[
                                        SizedBox(height: 8.h),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 32.w),
                                          child: Text(
                                            provider.errorMessage!,
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.red,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                      ),
                    ),
                  ],
                ],
              ),
              
              // Cart Button
              if (context.watch<CartProvider>().itemCount > 0)
                Positioned(
                  bottom: 20.h,
                  left: 20.w,
                  right: 20.w,
                  child: CustomButton(
                    text: 'View Cart (${context.watch<CartProvider>().itemCount} items)',
                    onPressed: () {
                      context.push('/cart');
                    },
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        // App bar shimmer
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          floating: false,
          pinned: false,
          toolbarHeight: 60.h,
          title: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 20.h,
              width: 120.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        ),

        // Restaurant header shimmer
        SliverToBoxAdapter(
          child: Container(
            height: 200.h,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Restaurant info shimmer
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant name
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 24.h,
                    width: 200.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                
                // Restaurant details
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16.h,
                    width: 150.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                
                // Rating and info row
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 16.h,
                        width: 60.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 16.h,
                        width: 80.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Tab bar shimmer
        SliverPersistentHeader(
          pinned: true,
          delegate: _ShimmerTabBarDelegate(),
        ),

        // Menu items shimmer
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: List.generate(6, (index) => Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 18.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          
                          // Product description
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 14.h,
                              width: 180.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          
                          // Price
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 16.h,
                              width: 60.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    
                    // Product image
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ),
          ),
        ),

        // Loading indicator
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(32.w),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading menu...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

}

class _ShimmerTabBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 48.h;
  
  @override
  double get maxExtent => 48.h;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 48.h,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_ShimmerTabBarDelegate oldDelegate) => false;
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}