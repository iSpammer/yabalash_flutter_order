import 'package:flutter/foundation.dart';
import '../models/category_detail_model.dart';
import '../services/category_service.dart';
import '../../restaurants/models/product_model.dart';
import '../../restaurants/models/restaurant_model.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  // Category details
  CategoryDetailModel? _categoryDetail;
  bool _isLoadingCategory = false;
  String? _categoryError;

  // Products
  List<ProductModel> _products = [];
  bool _isLoadingProducts = false;
  bool _isLoadingMoreProducts = false;
  String? _productsError;
  CategoryPagination? _pagination;
  
  // Vendors (for vendor categories)
  List<RestaurantModel> _vendors = [];
  bool _isVendorCategory = false;

  // Filters and sorting
  CategoryFilters _filters = CategoryFilters();
  CategorySortOption _selectedSort = CategorySortOption.popularity;
  
  // Price range
  double _minPrice = 0.0;
  double _maxPrice = 500.0;
  double _currentMinPrice = 0.0;
  double _currentMaxPrice = 500.0;

  // Search within category
  String _searchQuery = '';
  bool _isSearching = false;

  // Location
  double? _latitude;
  double? _longitude;
  
  // Delivery type
  String _deliveryType = 'delivery';

  // Getters
  CategoryDetailModel? get categoryDetail => _categoryDetail;
  bool get isLoadingCategory => _isLoadingCategory;
  String? get categoryError => _categoryError;

  List<ProductModel> get products => _products;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingMoreProducts => _isLoadingMoreProducts;
  String? get productsError => _productsError;
  CategoryPagination? get pagination => _pagination;
  
  List<RestaurantModel> get vendors => _vendors;
  bool get isVendorCategory => _isVendorCategory;

  CategoryFilters get filters => _filters;
  CategorySortOption get selectedSort => _selectedSort;

  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  double get currentMinPrice => _currentMinPrice;
  double get currentMaxPrice => _currentMaxPrice;

  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;

  bool get hasNextPage => _pagination?.hasNextPage ?? false;
  bool get hasPreviousPage => _pagination?.hasPreviousPage ?? false;
  
  int get totalProducts => _isVendorCategory 
      ? _vendors.length 
      : (_pagination?.totalItems ?? _products.length);
  int get currentPage => _pagination?.currentPage ?? 1;

  // Helper getters
  bool get hasFiltersApplied => 
      _filters.minPrice != null || 
      _filters.maxPrice != null || 
      _filters.minRating != null || 
      _filters.inStockOnly == true ||
      _searchQuery.isNotEmpty;

  String get filtersDisplayText {
    List<String> appliedFilters = [];
    
    if (_filters.minPrice != null || _filters.maxPrice != null) {
      appliedFilters.add('Price: AED ${_filters.minPrice?.toInt() ?? 0}-AED ${_filters.maxPrice?.toInt() ?? 500}');
    }
    
    if (_filters.minRating != null) {
      appliedFilters.add('Rating: ${_filters.minRating}+ stars');
    }
    
    if (_filters.inStockOnly == true) {
      appliedFilters.add('In stock only');
    }

    if (_searchQuery.isNotEmpty) {
      appliedFilters.add('Search: "$_searchQuery"');
    }
    
    return appliedFilters.join(', ');
  }

  // Set location
  void setLocation({double? latitude, double? longitude}) {
    _latitude = latitude;
    _longitude = longitude;
    notifyListeners();
  }
  
  // Set delivery type
  void setDeliveryType(String type) {
    _deliveryType = type;
    notifyListeners();
  }

  // Load category details
  Future<void> loadCategoryDetails(int categoryId) async {
    _isLoadingCategory = true;
    _categoryError = null;
    notifyListeners();

    try {
      final response = await _categoryService.getCategoryDetails(
        categoryId: categoryId,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (response.success && response.data != null) {
        _categoryDetail = response.data;
        _categoryError = null;
        
        // Load products/vendors based on category type
        await loadProducts(categoryId, refresh: true);
      } else {
        _categoryError = response.message ?? 'Failed to load category details';
      }
    } catch (e) {
      _categoryError = 'An error occurred: $e';
      debugPrint('Error loading category details: $e');
    } finally {
      _isLoadingCategory = false;
      notifyListeners();
    }
  }

  // Load products with current filters
  Future<void> loadProducts(int categoryId, {bool refresh = false}) async {
    if (refresh) {
      _products.clear();
      _vendors.clear();
      _pagination = null;
      _isVendorCategory = false;
    }

    _isLoadingProducts = refresh;
    _isLoadingMoreProducts = !refresh;
    _productsError = null;
    notifyListeners();

    try {
      final currentPage = refresh ? 1 : ((_pagination?.currentPage ?? 0) + 1);
      
      final response = await _categoryService.getCategoryProducts(
        categoryId: categoryId,
        page: currentPage,
        limit: 5, // Match React Native default
        filters: _filters,
        latitude: _latitude,
        longitude: _longitude,
        deliveryType: _deliveryType,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!;
        
        // Check if this is a vendor category
        _isVendorCategory = responseData.isVendorCategory;
        
        debugPrint('Category response - isVendorCategory: $_isVendorCategory');
        debugPrint('Vendors data: ${responseData.vendors?.length ?? 0}');
        debugPrint('Products data: ${responseData.products.length}');
        
        if (_isVendorCategory && responseData.vendors != null) {
          // Handle vendor category
          debugPrint('Processing ${responseData.vendors!.length} vendors');
          final newVendors = responseData.vendors!
              .map((json) => RestaurantModel.fromJson(json))
              .toList();
          
          if (refresh) {
            _vendors = newVendors;
          } else {
            _vendors.addAll(newVendors);
          }
          debugPrint('Total vendors after processing: ${_vendors.length}');
        } else {
          // Handle product category
          final newProducts = responseData.products
              .map((json) => ProductModel.fromJson(json))
              .toList();

          if (refresh) {
            _products = newProducts;
          } else {
            _products.addAll(newProducts);
          }
        }

        _pagination = responseData.pagination;
        _productsError = null;
      } else {
        _productsError = response.message ?? 'Failed to load items';
      }
    } catch (e) {
      _productsError = 'An error occurred: $e';
      debugPrint('Error loading category items: $e');
    } finally {
      _isLoadingProducts = false;
      _isLoadingMoreProducts = false;
      notifyListeners();
    }
  }

  // Search products within category
  Future<void> searchProducts(int categoryId, String query) async {
    _searchQuery = query;
    _isSearching = true;
    notifyListeners();

    // Update filters to include search
    _updateFiltersForSearch();

    // Load products with search query
    await loadProducts(categoryId, refresh: true);
    
    _isSearching = false;
    notifyListeners();
  }

  // Clear search
  Future<void> clearSearch(int categoryId) async {
    _searchQuery = '';
    _isSearching = false;
    
    // Remove search from filters
    _updateFiltersForSearch();
    
    // Reload products without search
    await loadProducts(categoryId, refresh: true);
  }

  // Apply sorting
  Future<void> applySorting(int categoryId, CategorySortOption sortOption) async {
    _selectedSort = sortOption;
    
    _filters = _filters.copyWith(
      sortBy: sortOption.field,
      sortOrder: sortOption.order,
    );

    await loadProducts(categoryId, refresh: true);
  }

  // Apply price range filter
  Future<void> applyPriceRange(int categoryId, double minPrice, double maxPrice) async {
    _currentMinPrice = minPrice;
    _currentMaxPrice = maxPrice;
    
    _filters = _filters.copyWith(
      minPrice: minPrice > _minPrice ? minPrice : null,
      maxPrice: maxPrice < _maxPrice ? maxPrice : null,
    );

    await loadProducts(categoryId, refresh: true);
  }

  // Apply rating filter
  Future<void> applyRatingFilter(int categoryId, double? minRating) async {
    _filters = _filters.copyWith(minRating: minRating);
    await loadProducts(categoryId, refresh: true);
  }

  // Toggle in-stock filter
  Future<void> toggleInStockFilter(int categoryId) async {
    _filters = _filters.copyWith(
      inStockOnly: _filters.inStockOnly != true,
    );
    await loadProducts(categoryId, refresh: true);
  }

  // Clear all filters
  Future<void> clearAllFilters(int categoryId) async {
    _filters = CategoryFilters();
    _selectedSort = CategorySortOption.popularity;
    _currentMinPrice = _minPrice;
    _currentMaxPrice = _maxPrice;
    _searchQuery = '';
    
    await loadProducts(categoryId, refresh: true);
  }

  // Load more products (pagination)
  Future<void> loadMoreProducts(int categoryId) async {
    if (_isLoadingMoreProducts || !hasNextPage) return;
    
    await loadProducts(categoryId, refresh: false);
  }

  // Refresh all data
  Future<void> refresh(int categoryId) async {
    await loadCategoryDetails(categoryId);
  }

  // Update price range limits (called when loading filter options)
  void updatePriceRange({double? minPrice, double? maxPrice}) {
    if (minPrice != null) _minPrice = minPrice;
    if (maxPrice != null) _maxPrice = maxPrice;
    
    // Update current values if they're outside the new range
    if (_currentMinPrice < _minPrice) _currentMinPrice = _minPrice;
    if (_currentMaxPrice > _maxPrice) _currentMaxPrice = _maxPrice;
    
    notifyListeners();
  }

  // Private helper methods
  void _updateFiltersForSearch() {
    // Note: Search is handled separately in the API call
    // This method can be used to update other filter logic if needed
    notifyListeners();
  }

  // Clear error states
  void clearErrors() {
    _categoryError = null;
    _productsError = null;
    notifyListeners();
  }

  // Get share text for category
  String getShareText() {
    if (_categoryDetail == null) return 'Check out this category on Yabalash!';
    
    final sb = StringBuffer();
    sb.writeln('🛍️ ${_categoryDetail!.name}');
    
    if (_categoryDetail!.description != null && _categoryDetail!.description!.isNotEmpty) {
      sb.writeln(_categoryDetail!.description!);
    }
    
    if (_isVendorCategory) {
      sb.writeln('\n🏪 ${_vendors.length} vendors available');
    } else {
      sb.writeln('\n📦 ${totalProducts} products available');
    }
    
    // Add filters if applied
    if (hasFiltersApplied) {
      sb.writeln('\n🔍 Filtered by: $filtersDisplayText');
    }
    
    // Add share link if available
    if (_categoryDetail!.shareLink != null && _categoryDetail!.shareLink!.isNotEmpty) {
      sb.writeln('\n🔗 ${_categoryDetail!.shareLink}');
    } else {
      sb.writeln('\n🔗 Check it out on Yabalash!');
    }
    
    return sb.toString();
  }
}