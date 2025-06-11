import 'package:flutter/foundation.dart';
import '../models/restaurant_model.dart';
import '../models/menu_category_model.dart';
import '../models/product_model.dart';
import '../services/restaurant_service.dart';

class RestaurantProvider extends ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();
  
  RestaurantModel? _currentRestaurant;
  List<MenuCategoryModel> _menuCategories = [];
  Map<int, List<ProductModel>> _categoryProducts = {};
  bool _isLoading = false;
  String? _errorMessage;
  
  // Search and filter
  String _searchQuery = '';
  int? _selectedCategoryId;
  
  // Getters
  RestaurantModel? get currentRestaurant => _currentRestaurant;
  List<MenuCategoryModel> get menuCategories => _menuCategories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  
  // Get products by category
  List<ProductModel> getProductsByCategory(int categoryId) {
    return _categoryProducts[categoryId] ?? [];
  }
  
  // Get all products
  List<ProductModel> get allProducts {
    List<ProductModel> products = [];
    _categoryProducts.forEach((key, value) {
      products.addAll(value);
    });
    return products;
  }
  
  // Get filtered products
  List<ProductModel> get filteredProducts {
    List<ProductModel> products = _selectedCategoryId != null
        ? getProductsByCategory(_selectedCategoryId!)
        : allProducts;
        
    if (_searchQuery.isNotEmpty) {
      products = products.where((product) =>
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (product.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    return products;
  }
  
  // Clear/reset state when switching restaurants
  void clearState() {
    _currentRestaurant = null;
    _menuCategories.clear();
    _categoryProducts.clear();
    _errorMessage = null;
    _searchQuery = '';
    _selectedCategoryId = null;
    _isLoading = false;
    notifyListeners();
  }

  // Load restaurant details
  Future<void> loadRestaurantDetails(int restaurantId) async {
    // Clear previous restaurant data first
    clearState();
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Get restaurant details
      final response = await _restaurantService.getRestaurantDetails(
        restaurantId: restaurantId,
      );
      
      if (response.success && response.data != null) {
        _currentRestaurant = response.data;
        
        debugPrint('Restaurant loaded: ${_currentRestaurant!.name}');
        debugPrint('Restaurant isOpen: ${_currentRestaurant!.isOpen}');
        debugPrint('Products in response: ${_currentRestaurant!.products?.length ?? 0}');
        debugPrint('Categories in response: ${_currentRestaurant!.categories?.length ?? 0}');
        
        // Always call _loadProductsFromVendorResponse as it handles both cases
        debugPrint('Loading products and categories from vendor response');
        _loadProductsFromVendorResponse();
      } else {
        _errorMessage = response.message ?? 'Failed to load restaurant details';
      }
    } catch (error) {
      debugPrint('Error in loadRestaurantDetails: $error');
      debugPrint('Error stackTrace: ${StackTrace.current}');
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load menu categories
  Future<void> _loadMenuCategories(int vendorId) async {
    try {
      final response = await _restaurantService.getVendorCategories(vendorId: vendorId);
      
      if (response.success && response.data != null) {
        _menuCategories = response.data!;
        
        // If categories were created from products (fallback scenario),
        // the products are already available, so no need to load them again
        bool categoriesFromProducts = false;
        
        // Load products for each category
        for (var category in _menuCategories) {
          final existingProducts = _categoryProducts[category.id];
          if (existingProducts == null || existingProducts.isEmpty) {
            await _loadCategoryProducts(vendorId, category.id);
          } else {
            categoriesFromProducts = true;
          }
        }
        
        if (categoriesFromProducts) {
          debugPrint('Categories were created from products, skipping additional product loading');
        }
      } else {
        // If categories failed to load, try to get all products directly
        debugPrint('Failed to load categories, trying to load all vendor products');
        await _loadAllVendorProducts(vendorId);
      }
    } catch (error) {
      debugPrint('Error loading categories: $error');
      // Fallback to loading all vendor products
      await _loadAllVendorProducts(vendorId);
    }
  }
  
  // Load all vendor products as fallback
  Future<void> _loadAllVendorProducts(int vendorId) async {
    try {
      final response = await _restaurantService.getVendorProducts(vendorId: vendorId);
      
      if (response.success && response.data != null) {
        // Group products by category
        Map<int, List<ProductModel>> productsByCategory = {};
        Set<String> categoryNames = {};
        
        for (var product in response.data!) {
          final categoryId = product.categoryId;
          if (!productsByCategory.containsKey(categoryId)) {
            productsByCategory[categoryId] = [];
          }
          productsByCategory[categoryId]!.add(product);
          if (product.categoryName != null) {
            categoryNames.add(product.categoryName!);
          }
        }
        
        _categoryProducts = productsByCategory;
        
        // Create categories from products
        _menuCategories = productsByCategory.entries.map((entry) {
          final categoryId = entry.key;
          final products = entry.value;
          final categoryName = products.first.categoryName ?? 'Category $categoryId';
          
          return MenuCategoryModel(
            id: categoryId,
            name: categoryName,
            description: null,
            image: null,
            position: categoryId,
            isActive: true,
            productCount: products.length,
          );
        }).toList();
        
        debugPrint('Created ${_menuCategories.length} categories from ${response.data!.length} products');
      }
    } catch (error) {
      debugPrint('Error loading all vendor products: $error');
    }
  }
  
  // Load products for a category
  Future<void> _loadCategoryProducts(int vendorId, int categoryId) async {
    try {
      final response = await _restaurantService.getProductsByCategory(
        vendorId: vendorId,
        categoryId: categoryId,
      );
      
      if (response.success && response.data != null) {
        _categoryProducts[categoryId] = response.data!;
      }
    } catch (error) {
      debugPrint('Error loading products for category $categoryId: $error');
    }
  }
  
  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  // Filter by category
  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }
  
  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    notifyListeners();
  }
  
  // Load products directly from vendor response
  void _loadProductsFromVendorResponse() {
    try {
      Map<int, List<ProductModel>> productsByCategory = {};
      List<MenuCategoryModel> categories = [];
      
      // First, check if we have products at the root level (from vendor endpoint)
      if (_currentRestaurant?.products != null && _currentRestaurant!.products!.isNotEmpty) {
        debugPrint('Found ${_currentRestaurant!.products!.length} products at root level');
        
        // Process all products
        for (var productJson in _currentRestaurant!.products!) {
          try {
            if (productJson is Map<String, dynamic>) {
              final product = ProductModel.fromJson(productJson);
              final categoryId = product.categoryId;
              
              if (!productsByCategory.containsKey(categoryId)) {
                productsByCategory[categoryId] = [];
              }
              productsByCategory[categoryId]!.add(product);
              debugPrint('Added product ${product.name} to category $categoryId');
            }
          } catch (e) {
            debugPrint('Error parsing product: $e');
          }
        }
      }
      
      // Then process categories
      if (_currentRestaurant?.categories != null && _currentRestaurant!.categories!.isNotEmpty) {
        debugPrint('Processing ${_currentRestaurant!.categories!.length} categories');
        
        for (var categoryJson in _currentRestaurant!.categories!) {
          try {
            if (categoryJson is Map<String, dynamic>) {
              final categoryModel = MenuCategoryModel.fromJson(categoryJson);
              categories.add(categoryModel);
              
              // Check if category has embedded products (vendor/5 structure)
              if (categoryJson['products'] != null && categoryJson['products'] is List) {
                final categoryProducts = <ProductModel>[];
                
                for (var productJson in categoryJson['products']) {
                  try {
                    if (productJson is Map<String, dynamic>) {
                      final product = ProductModel.fromJson(productJson);
                      categoryProducts.add(product);
                    }
                  } catch (e) {
                    debugPrint('Error parsing product in category: $e');
                  }
                }
                
                if (categoryProducts.isNotEmpty) {
                  // Merge with existing products or replace
                  if (productsByCategory.containsKey(categoryModel.id)) {
                    productsByCategory[categoryModel.id]!.addAll(categoryProducts);
                  } else {
                    productsByCategory[categoryModel.id] = categoryProducts;
                  }
                  debugPrint('Category ${categoryModel.id} has ${categoryProducts.length} embedded products');
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing category: $e');
          }
        }
        
        _menuCategories = categories;
      }
      
      // If we have no categories but have products, create categories from products
      if (_menuCategories.isEmpty && productsByCategory.isNotEmpty) {
        debugPrint('No categories found, creating from ${productsByCategory.length} product groups');
        _menuCategories = productsByCategory.entries.map((entry) {
          final categoryId = entry.key;
          final categoryProducts = entry.value;
          final categoryName = categoryProducts.first.categoryName ?? 'Category $categoryId';
          
          return MenuCategoryModel(
            id: categoryId,
            name: categoryName,
            description: null,
            image: null,
            position: categoryId,
            isActive: true,
            productCount: categoryProducts.length,
          );
        }).toList();
      }
      
      _categoryProducts = productsByCategory;
      
      // Log results
      debugPrint('Final result: ${_menuCategories.length} categories');
      int totalProducts = 0;
      productsByCategory.forEach((key, value) {
        totalProducts += value.length;
        debugPrint('Category $key has ${value.length} products');
      });
      debugPrint('Total products loaded: $totalProducts');
    } catch (error, stackTrace) {
      debugPrint('Error loading products from vendor response: $error');
      debugPrint('Stack trace: $stackTrace');
      
      // Fallback to separate API calls
      if (_currentRestaurant?.id != null) {
        _loadMenuCategories(_currentRestaurant!.id!);
      }
    }
  }
  
  // Refresh restaurant data
  Future<void> refresh() async {
    if (_currentRestaurant != null && _currentRestaurant!.id != null) {
      await loadRestaurantDetails(_currentRestaurant!.id!);
    }
  }
}