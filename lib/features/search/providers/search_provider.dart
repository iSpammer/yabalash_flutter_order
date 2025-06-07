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
  String? _errorMessage;
  
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
  String get currentQuery => _currentQuery;
  List<RestaurantModel> get restaurants => _restaurants;
  List<ProductModel> get products => _products;
  String? get errorMessage => _errorMessage;
  bool get hasResults => _restaurants.isNotEmpty || _products.isNotEmpty;

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
      _errorMessage = null;
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
    _currentQuery = '';
    _errorMessage = null;
    _isLoading = false;
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
}