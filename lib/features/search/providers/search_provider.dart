import 'package:flutter/foundation.dart';
import '../services/search_service.dart';
import '../../restaurants/models/restaurant_model.dart';
import '../../restaurants/models/product_model.dart';
import '../../profile/providers/address_provider.dart';
import 'package:geolocator/geolocator.dart';

class SearchProvider extends ChangeNotifier {
  final SearchService _searchService = SearchService();
  AddressProvider? _addressProvider;
  Position? _currentLocation;
  
  bool _isLoading = false;
  String _currentQuery = '';
  List<RestaurantModel> _restaurants = [];
  List<ProductModel> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _brands = [];
  String? _errorMessage;
  
  // Search history
  List<String> _searchHistory = [];
  
  // Voice search support
  bool _isVoiceSearching = false;
  
  // Dependency injection
  void setAddressProvider(AddressProvider addressProvider) {
    _addressProvider = addressProvider;
  }
  
  void setCurrentLocation(Position? location) {
    _currentLocation = location;
  }
  
  // Get location coordinates to use for search
  (double?, double?) get locationCoordinates {
    final selected = _addressProvider?.selectedAddress;
    
    // If we have a selected address with coordinates, use it
    if (selected != null && selected.id != 'current_location' && 
        selected.latitude != null && selected.longitude != null) {
      return (selected.latitude, selected.longitude);
    }
    
    // Otherwise use current GPS location
    if (_currentLocation != null) {
      return (_currentLocation!.latitude, _currentLocation!.longitude);
    }
    
    return (null, null);
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isVoiceSearching => _isVoiceSearching;
  String get currentQuery => _currentQuery;
  List<RestaurantModel> get restaurants => _restaurants;
  List<ProductModel> get products => _products;
  List<dynamic> get categories => _categories;
  List<dynamic> get brands => _brands;
  List<String> get searchHistory => _searchHistory;
  String? get errorMessage => _errorMessage;
  bool get hasResults => _restaurants.isNotEmpty || _products.isNotEmpty || _categories.isNotEmpty || _brands.isNotEmpty;
  
  // Get total results count
  int get totalResults => _restaurants.length + _products.length + _categories.length + _brands.length;

  Future<void> search(String query, {String type = 'delivery'}) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    _isLoading = true;
    _currentQuery = query;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get location coordinates
      final (lat, lng) = locationCoordinates;
      
      // Search for restaurants and products simultaneously
      final searchResults = await _searchService.searchAll(
        query, 
        type: type,
        latitude: lat,
        longitude: lng,
      );
      
      _restaurants = searchResults['restaurants'] as List<RestaurantModel>;
      _products = searchResults['products'] as List<ProductModel>;
      _categories = searchResults['categories'] as List? ?? [];
      _brands = searchResults['brands'] as List? ?? [];
      _errorMessage = null;
      
      // Add to search history if successful
      if (hasResults) {
        _addToSearchHistory(query);
      }
    } catch (e) {
      _errorMessage = 'Search failed: ${e.toString()}';
      _restaurants = [];
      _products = [];
      debugPrint('Search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _restaurants = [];
    _products = [];
    _categories = [];
    _brands = [];
    _currentQuery = '';
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
  
  // Add query to search history
  void _addToSearchHistory(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty && !_searchHistory.contains(trimmedQuery)) {
      _searchHistory.insert(0, trimmedQuery);
      // Keep only last 10 searches
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.take(10).toList();
      }
    }
  }
  
  // Clear search history
  void clearSearchHistory() {
    _searchHistory.clear();
    notifyListeners();
  }
  
  // Remove item from search history
  void removeFromSearchHistory(String query) {
    _searchHistory.remove(query);
    notifyListeners();
  }
  
  // Set voice search state
  void setVoiceSearching(bool isVoiceSearching) {
    _isVoiceSearching = isVoiceSearching;
    notifyListeners();
  }

  Future<void> searchRestaurants(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get location coordinates
      final (lat, lng) = locationCoordinates;
      
      _restaurants = await _searchService.searchRestaurants(
        query,
        latitude: lat,
        longitude: lng,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Restaurant search failed: ${e.toString()}';
      _restaurants = [];
      debugPrint('Restaurant search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get location coordinates
      final (lat, lng) = locationCoordinates;
      
      _products = await _searchService.searchProducts(
        query,
        latitude: lat,
        longitude: lng,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Product search failed: ${e.toString()}';
      _products = [];
      debugPrint('Product search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Search by category ID
  Future<void> searchByCategory(String query, int categoryId, {String type = 'delivery'}) async {
    _isLoading = true;
    _currentQuery = query;
    _errorMessage = null;
    notifyListeners();

    try {
      final (lat, lng) = locationCoordinates;
      
      final searchResults = await _searchService.searchByCategory(
        query,
        categoryId,
        type: type,
        latitude: lat,
        longitude: lng,
      );
      
      _restaurants = searchResults['restaurants'] as List<RestaurantModel>;
      _products = searchResults['products'] as List<ProductModel>;
      _categories = [];
      _brands = [];
      _errorMessage = null;
      
      if (hasResults) {
        _addToSearchHistory(query);
      }
    } catch (e) {
      _errorMessage = 'Category search failed: ${e.toString()}';
      _restaurants = [];
      _products = [];
      _categories = [];
      _brands = [];
      debugPrint('Category search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Search by vendor ID
  Future<void> searchByVendor(String query, int vendorId, {String type = 'delivery'}) async {
    _isLoading = true;
    _currentQuery = query;
    _errorMessage = null;
    notifyListeners();

    try {
      final (lat, lng) = locationCoordinates;
      
      final products = await _searchService.searchByVendor(
        query,
        vendorId,
        type: type,
        latitude: lat,
        longitude: lng,
      );
      
      _restaurants = [];
      _products = products;
      _categories = [];
      _brands = [];
      _errorMessage = null;
      
      if (hasResults) {
        _addToSearchHistory(query);
      }
    } catch (e) {
      _errorMessage = 'Vendor search failed: ${e.toString()}';
      _restaurants = [];
      _products = [];
      _categories = [];
      _brands = [];
      debugPrint('Vendor search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Search by brand ID
  Future<void> searchByBrand(String query, int brandId, {String type = 'delivery'}) async {
    _isLoading = true;
    _currentQuery = query;
    _errorMessage = null;
    notifyListeners();

    try {
      final (lat, lng) = locationCoordinates;
      
      final searchResults = await _searchService.searchByBrand(
        query,
        brandId,
        type: type,
        latitude: lat,
        longitude: lng,
      );
      
      _restaurants = searchResults['restaurants'] as List<RestaurantModel>;
      _products = searchResults['products'] as List<ProductModel>;
      _categories = [];
      _brands = [];
      _errorMessage = null;
      
      if (hasResults) {
        _addToSearchHistory(query);
      }
    } catch (e) {
      _errorMessage = 'Brand search failed: ${e.toString()}';
      _restaurants = [];
      _products = [];
      _categories = [];
      _brands = [];
      debugPrint('Brand search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}