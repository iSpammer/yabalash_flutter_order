import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../../restaurants/widgets/restaurant_card_v2.dart';
import '../../categories/widgets/enhanced_product_card.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late SearchProvider _searchProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _searchProvider = context.read<SearchProvider>();
    
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      _searchProvider.search(query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search restaurants, food, items...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14.sp,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[500],
                size: 20.sp,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[500]),
                      onPressed: () {
                        _searchController.clear();
                        _searchProvider.clearResults();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            onChanged: (query) {
              setState(() {});
              // Debounce search
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == query && query.trim().isNotEmpty) {
                  _performSearch(query);
                }
              });
            },
            onSubmitted: _performSearch,
          ),
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, _) {
          if (_searchController.text.isEmpty) {
            return _buildSearchSuggestions();
          }

          if (searchProvider.isLoading) {
            return _buildLoadingState();
          }

          if (searchProvider.hasResults) {
            return Column(
              children: [
                _buildTabBar(searchProvider),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRestaurantsTab(searchProvider.restaurants),
                      _buildProductsTab(searchProvider.products),
                      _buildAllResultsTab(searchProvider),
                    ],
                  ),
                ),
              ],
            );
          }

          return _buildNoResultsState();
        },
      ),
    );
  }

  Widget _buildTabBar(SearchProvider searchProvider) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant, size: 16.sp),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    'Restaurants (${searchProvider.restaurants.length})',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fastfood, size: 16.sp),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    'Food (${searchProvider.products.length})',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.view_list, size: 16.sp),
                SizedBox(width: 4.w),
                Text('All'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantsTab(List restaurants) {
    if (restaurants.isEmpty) {
      return _buildEmptyTabState('No restaurants found');
    }

    return ListView.builder(
      padding: EdgeInsets.all(8.w),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        return RestaurantCardV2(
          restaurant: restaurant,
          onTap: () => context.push('/restaurant/${restaurant.id}'),
        );
      },
    );
  }

  Widget _buildProductsTab(List products) {
    if (products.isEmpty) {
      return _buildEmptyTabState('No food items found');
    }

    return ListView.builder(
      padding: EdgeInsets.all(8.w),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return EnhancedProductCard(
          product: product,
          showVendorName: true,
          onTap: () => context.push('/product/${product.id}'),
          onAddToCart: () {
            // Handle add to cart for complex products
          },
        );
      },
    );
  }

  Widget _buildAllResultsTab(SearchProvider searchProvider) {
    return ListView(
      padding: EdgeInsets.all(8.w),
      children: [
        if (searchProvider.restaurants.isNotEmpty) ...[
          _buildSectionHeader('Restaurants'),
          ...searchProvider.restaurants.take(3).map((restaurant) =>
              RestaurantCardV2(
                restaurant: restaurant,
                onTap: () => context.push('/restaurant/${restaurant.id}'),
              )),
          if (searchProvider.restaurants.length > 3)
            _buildViewAllButton('restaurants'),
          SizedBox(height: 16.h),
        ],
        if (searchProvider.products.isNotEmpty) ...[
          _buildSectionHeader('Food Items'),
          ...searchProvider.products.take(3).map((product) =>
              EnhancedProductCard(
                product: product,
                showVendorName: true,
                onTap: () => context.push('/product/${product.id}'),
                onAddToCart: () {
                  // Handle add to cart for complex products
                },
              )),
          if (searchProvider.products.length > 3)
            _buildViewAllButton('products'),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
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

  Widget _buildViewAllButton(String type) {
    return TextButton(
      onPressed: () {
        // Switch to appropriate tab
        _tabController.animateTo(type == 'restaurants' ? 0 : 1);
      },
      child: Text('View All ${type == 'restaurants' ? 'Restaurants' : 'Food Items'}'),
    );
  }

  Widget _buildSearchSuggestions() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              'Pizza',
              'Burger',
              'Sushi',
              'Chinese',
              'Italian',
              'Fast Food',
            ].map((suggestion) => _buildSuggestionChip(suggestion)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () {
        _searchController.text = suggestion;
        _performSearch(suggestion);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: 16.sp,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}