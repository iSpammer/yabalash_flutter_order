import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_grid.dart';
import '../widgets/section_widget_factory.dart';
import '../widgets/delivery_pickup_toggle.dart';
import '../widgets/animated_content_wrapper.dart';
import '../../restaurants/widgets/restaurant_card_v2.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/address_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeDashboard() async {
    final dashboardProvider = context.read<DashboardProvider>();
    final addressProvider = context.read<AddressProvider>();
    
    // Set up the address provider dependency
    dashboardProvider.setAddressProvider(addressProvider);
    
    // Load addresses and set default if not selected
    await addressProvider.fetchAddresses();
    
    // Get current location for fallback
    await dashboardProvider.getCurrentLocation();
    
    // Load dashboard data
    await dashboardProvider.loadDashboardData();
  }

  void _onRefresh() async {
    final dashboardProvider = context.read<DashboardProvider>();
    await dashboardProvider.refreshData();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dashboardProvider, _) {
            if (dashboardProvider.isLoading && dashboardProvider.dashboardData == null) {
              return _buildLoadingState();
            }

            if (dashboardProvider.errorMessage != null && dashboardProvider.dashboardData == null) {
              return _buildErrorState(dashboardProvider.errorMessage!);
            }

            return SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              header: const WaterDropHeader(),
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  _buildDeliveryPickupToggle(),
                  _buildLocationIndicator(),
                  _buildSearchBar(),
                  _buildContent(dashboardProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Hero(
            tag: 'app_logo',
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 36.w,
                    height: 36.w,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 18.sp,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getGreeting()}!',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      authProvider.user?.name ?? 'Guest',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.account_circle_outlined,
            color: Colors.black87,
            size: 24.sp,
          ),
          onPressed: () {
            context.go('/profile');
          },
        ),
      ],
    );
  }

  Widget _buildDeliveryPickupToggle() {
    return SliverToBoxAdapter(
      child: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, _) {
          return Container(
            color: Colors.white,
            child: DeliveryPickupToggle(
              selectedMode: dashboardProvider.deliveryMode,
              onModeChanged: (mode) {
                dashboardProvider.setDeliveryMode(mode);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationIndicator() {
    return SliverToBoxAdapter(
      child: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, _) {
          return GestureDetector(
            onTap: () {
              // Navigate to address selection
              context.push('/addresses/select');
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).primaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivering to',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          dashboardProvider.currentLocationName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey[600],
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(16.w),
        color: Colors.white,
        child: GestureDetector(
          onTap: () {
            context.push('/search');
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25.r),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.grey[500],
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Search for restaurants, food...',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(DashboardProvider dashboardProvider) {
    // Check if we have dynamic sections from the V2 API
    if (dashboardProvider.sections.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Render all dynamic sections with animations
            ...dashboardProvider.sections.asMap().entries.map((entry) {
              int index = entry.key;
              var section = entry.value;
              return AnimatedContentWrapper(
                delay: index * 100,
                child: SectionWidgetFactory.buildSection(section, context: context),
              );
            }),
            // Add extra padding for transparent navigation bar
            SizedBox(height: 100.h),
          ],
        ),
      );
    }

    // Fallback to legacy content if no dynamic sections are available
    final hasAnyContent = dashboardProvider.banners.isNotEmpty ||
        dashboardProvider.categories.isNotEmpty ||
        dashboardProvider.featuredRestaurants.isNotEmpty ||
        dashboardProvider.nearbyRestaurants.isNotEmpty;
    
    if (!hasAnyContent) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banners with animation
          if (dashboardProvider.banners.isNotEmpty) ...[
            SizedBox(height: 16.h),
            AnimatedContentWrapper(
              delay: 0,
              child: BannerCarousel(
                banners: dashboardProvider.banners,
                onBannerTap: (banner) {
                  // Handle banner tap
                  if (banner.actionType == 'vendor' && banner.actionId != null) {
                    context.push('/restaurant/${banner.actionId}');
                  } else if (banner.redirectionUrl != null) {
                    // Handle external URL
                  }
                },
              ),
            ),
          ],

          // Categories with animation
          if (dashboardProvider.categories.isNotEmpty) ...[
            SizedBox(height: 24.h),
            AnimatedContentWrapper(
              delay: 100,
              child: _buildSectionHeader('Categories'),
            ),
            SizedBox(height: 12.h),
            AnimatedContentWrapper(
              delay: 150,
              child: CategoryGrid(
                categories: dashboardProvider.categories,
                showMoreButton: true,
                onCategoryTap: (category) {
                  // Navigate to category screen with image
                  final params = {
                    'name': Uri.encodeComponent(category.name ?? 'Category'),
                    if (category.image != null) 'image': Uri.encodeComponent(category.image!),
                  };
                  final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
                  context.push('/category/${category.id}?$queryString');
                },
              ),
            ),
          ] else ...[
            // Show placeholder categories when none are available
            SizedBox(height: 24.h),
            AnimatedContentWrapper(
              delay: 100,
              child: _buildSectionHeader('Browse Categories'),
            ),
            SizedBox(height: 12.h),
            AnimatedContentWrapper(
              delay: 150,
              child: _buildPlaceholderCategories(),
            ),
          ],

          // Featured Restaurants
          if (dashboardProvider.featuredRestaurants.isNotEmpty) ...[
            SizedBox(height: 24.h),
            AnimatedContentWrapper(
              delay: 200,
              child: _buildSectionHeader('Featured Restaurants'),
            ),
            SizedBox(height: 12.h),
            AnimatedContentWrapper(
              delay: 250,
              child: SizedBox(
                height: 200.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  itemCount: dashboardProvider.featuredRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = dashboardProvider.featuredRestaurants[index];
                    return AnimatedContentWrapper(
                      delay: 300 + (index * 50),
                      child: SizedBox(
                        width: 280.w,
                        child: RestaurantCardV2(
                          restaurant: restaurant,
                          isHorizontal: false,
                          onTap: () {
                            context.push('/restaurant/${restaurant.id}');
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Nearby Restaurants
          if (dashboardProvider.nearbyRestaurants.isNotEmpty) ...[
            SizedBox(height: 24.h),
            AnimatedContentWrapper(
              delay: 400,
              child: _buildSectionHeader('Nearby Restaurants', showViewToggle: true),
            ),
            SizedBox(height: 12.h),
            AnimatedContentWrapper(
              delay: 450,
              child: Consumer<DashboardProvider>(
                builder: (context, provider, _) {
                  if (provider.isCardView) {
                    // Card view
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      itemCount: provider.nearbyRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = provider.nearbyRestaurants[index];
                        return AnimatedContentWrapper(
                          delay: 500 + (index * 100),
                          child: RestaurantCardV2(
                            restaurant: restaurant,
                            isHorizontal: true,
                            onTap: () {
                              context.push('/restaurant/${restaurant.id}');
                            },
                          ),
                        );
                      },
                    );
                  } else {
                    // Grid view
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: provider.nearbyRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = provider.nearbyRestaurants[index];
                        return AnimatedContentWrapper(
                          delay: 500 + (index * 50),
                          child: RestaurantCardV2(
                            restaurant: restaurant,
                            isHorizontal: false,
                            onTap: () {
                              context.push('/restaurant/${restaurant.id}');
                            },
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ] else ...[
            // Show message when no restaurants are available
            SizedBox(height: 24.h),
            AnimatedContentWrapper(
              delay: 400,
              child: _buildNoRestaurantsMessage(),
            ),
          ],

          // Add extra padding for transparent navigation bar
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showViewToggle = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (showViewToggle)
            Consumer<DashboardProvider>(
              builder: (context, provider, _) {
                return IconButton(
                  onPressed: provider.toggleViewMode,
                  icon: Icon(
                    provider.isCardView 
                      ? Icons.view_list_rounded 
                      : Icons.view_module_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 24.sp,
                  ),
                  tooltip: provider.isCardView ? 'List View' : 'Card View',
                );
              },
            ),
        ],
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
          flexibleSpace: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 14.h,
                          width: 80.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          height: 12.h,
                          width: 120.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Delivery toggle shimmer
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
            ),
          ),
        ),

        // Location indicator shimmer
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ),

        // Search bar shimmer
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ),

        // Banner carousel shimmer
        SliverToBoxAdapter(
          child: Container(
            height: 180.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ),

        // Categories grid shimmer
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 20.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Column(
                        children: [
                          Container(
                            width: 60.w,
                            height: 60.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            height: 12.h,
                            width: 50.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Restaurant cards shimmer
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
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
                SizedBox(height: 12.h),
                ...List.generate(3, (index) => Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 120.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                )),
              ],
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
                    'Loading restaurants and offers...',
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

  Widget _buildErrorState(String error) {
    return Center(
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
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: 'Try Again',
              onPressed: _initializeDashboard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 50.h),
          Icon(
            Icons.restaurant_menu,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Welcome to Yabalash!',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Restaurants and categories will appear here once they are available in your area.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: 'Refresh',
            onPressed: _initializeDashboard,
            outlined: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaceholderCategories() {
    final placeholderCategories = [
      {'name': 'Restaurants', 'icon': Icons.restaurant},
      {'name': 'Fast Food', 'icon': Icons.fastfood},
      {'name': 'Coffee', 'icon': Icons.local_cafe},
      {'name': 'Desserts', 'icon': Icons.cake},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.8,
      ),
      itemCount: placeholderCategories.length,
      itemBuilder: (context, index) {
        final category = placeholderCategories[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: Colors.grey[600],
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                category['name'] as String,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildNoRestaurantsMessage() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 12.h),
          Text(
            'No restaurants available',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Restaurants will appear here once they become available in your area.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}