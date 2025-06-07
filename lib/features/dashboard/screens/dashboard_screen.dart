import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_grid.dart';
import '../widgets/section_widget_factory.dart';
import '../widgets/delivery_pickup_toggle.dart';
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
      title: Consumer<AuthProvider>(
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
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: Colors.black87,
            size: 24.sp,
          ),
          onPressed: () {
            // Navigate to notifications
          },
        ),
        IconButton(
          icon: Icon(
            Icons.account_circle_outlined,
            color: Colors.black87,
            size: 24.sp,
          ),
          onPressed: () {
            // Navigate to profile
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
            // Render all dynamic sections
            ...dashboardProvider.sections.map((section) {
              return SectionWidgetFactory.buildSection(section, context: context);
            }),
            SizedBox(height: 20.h),
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
          // Banners
          if (dashboardProvider.banners.isNotEmpty) ...[
            SizedBox(height: 16.h),
            BannerCarousel(
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
          ],

          // Categories
          if (dashboardProvider.categories.isNotEmpty) ...[
            SizedBox(height: 24.h),
            _buildSectionHeader('Categories'),
            SizedBox(height: 12.h),
            CategoryGrid(
              categories: dashboardProvider.categories,
              showMoreButton: true,
              onCategoryTap: (category) {
                // Navigate to category screen
                context.push('/category/${category.id}?name=${Uri.encodeComponent(category.name ?? 'Category')}');
              },
            ),
          ] else ...[
            // Show placeholder categories when none are available
            SizedBox(height: 24.h),
            _buildSectionHeader('Browse Categories'),
            SizedBox(height: 12.h),
            _buildPlaceholderCategories(),
          ],

          // Featured Restaurants
          if (dashboardProvider.featuredRestaurants.isNotEmpty) ...[
            SizedBox(height: 24.h),
            _buildSectionHeader('Featured Restaurants'),
            SizedBox(height: 12.h),
            SizedBox(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                itemCount: dashboardProvider.featuredRestaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = dashboardProvider.featuredRestaurants[index];
                  return SizedBox(
                    width: 280.w,
                    child: RestaurantCardV2(
                      restaurant: restaurant,
                      isHorizontal: false,
                      onTap: () {
                        context.push('/restaurant/${restaurant.id}');
                      },
                    ),
                  );
                },
              ),
            ),
          ],

          // Nearby Restaurants
          if (dashboardProvider.nearbyRestaurants.isNotEmpty) ...[
            SizedBox(height: 24.h),
            _buildSectionHeader('Nearby Restaurants'),
            SizedBox(height: 12.h),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              itemCount: dashboardProvider.nearbyRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = dashboardProvider.nearbyRestaurants[index];
                return RestaurantCardV2(
                  restaurant: restaurant,
                  isHorizontal: true,
                  onTap: () {
                    context.push('/restaurant/${restaurant.id}');
                  },
                );
              },
            ),
          ] else ...[
            // Show message when no restaurants are available
            SizedBox(height: 24.h),
            _buildNoRestaurantsMessage(),
          ],

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
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