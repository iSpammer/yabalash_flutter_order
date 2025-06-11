import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/dashboard_model.dart';
import '../models/dashboard_section.dart';
import '../models/category_model.dart';
import '../models/banner_model.dart';
import '../../restaurants/models/restaurant_model.dart';
import '../services/dashboard_service.dart';
import '../widgets/delivery_pickup_toggle.dart';
import '../../profile/providers/address_provider.dart';
import '../../profile/models/address_model.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  AddressProvider? _addressProvider;

  DashboardModel? _dashboardData;
  List<DashboardSection> _sections = [];
  List<CategoryModel> _categories = [];
  List<RestaurantModel> _featuredRestaurants = [];
  List<RestaurantModel> _nearbyRestaurants = [];
  List<RestaurantModel> _searchResults = [];

  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _isLoadingDashboard = false; // Guard against multiple concurrent loads

  Position? _currentLocation;
  String _searchQuery = '';
  int? _selectedCategoryId;
  DeliveryMode _deliveryMode = DeliveryMode.delivery;
  bool _isCardView = true; // Toggle between card and list view for restaurants

  // Dependency injection
  void setAddressProvider(AddressProvider addressProvider) {
    _addressProvider = addressProvider;
    // Listen to address selection changes
    _addressProvider?.addListener(_onAddressSelectionChanged);
  }

  @override
  void dispose() {
    _addressProvider?.removeListener(_onAddressSelectionChanged);
    super.dispose();
  }

  void _onAddressSelectionChanged() {
    // Only reload if we already have data (avoid reload during initialization)
    if (_dashboardData != null && !_isLoadingDashboard) {
      // Reload dashboard data when address selection changes
      loadDashboardData(refresh: true);
    }
  }

  // Getters
  DashboardModel? get dashboardData => _dashboardData;
  List<DashboardSection> get sections => _sections;
  List<CategoryModel> get categories => _categories;
  List<BannerModel> get banners => _dashboardData?.banners ?? [];
  List<RestaurantModel> get featuredRestaurants => _featuredRestaurants;
  List<RestaurantModel> get nearbyRestaurants => _nearbyRestaurants;
  List<RestaurantModel> get searchResults => _searchResults;

  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  Position? get currentLocation => _currentLocation;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  DeliveryMode get deliveryMode => _deliveryMode;
  bool get isCardView => _isCardView;

  // Get current selected address or location
  AddressModel? get selectedAddress => _addressProvider?.selectedAddress;
  String get currentLocationName {
    final selected = _addressProvider?.selectedAddress;
    if (selected == null || selected.id == 'current_location') {
      return 'Current Location';
    }
    return selected.label;
  }

  // Get location coordinates to use for API calls
  (double?, double?) get locationCoordinates {
    final selected = _addressProvider?.selectedAddress;

    // If we have a selected address with coordinates, use it
    if (selected != null &&
        selected.id != 'current_location' &&
        selected.latitude != null &&
        selected.longitude != null) {
      return (selected.latitude, selected.longitude);
    }

    // Otherwise use current GPS location
    if (_currentLocation != null) {
      return (_currentLocation!.latitude, _currentLocation!.longitude);
    }

    return (null, null);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setDeliveryMode(DeliveryMode mode, {bool skipReload = false}) {
    if (_deliveryMode != mode) {
      _deliveryMode = mode;
      notifyListeners();

      // Only reload if not skipping and if we have data
      if (!skipReload && _dashboardData != null) {
        // Set loading state when switching modes
        _isLoading = true;
        notifyListeners();
        // Refresh dashboard data with new mode
        loadDashboardData(refresh: true);
      }
    }
  }

  void toggleViewMode() {
    _isCardView = !_isCardView;
    notifyListeners();
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled';
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permissions are denied';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied';
        notifyListeners();
        return;
      }

      _currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get current location: $e';
      notifyListeners();
    }
  }

  Future<void> loadDashboardData({bool refresh = false}) async {
    // Prevent multiple concurrent loads
    if (_isLoadingDashboard) {
      return;
    }

    if (refresh) {
      _isLoading = true;
    } else if (_dashboardData != null) {
      return; // Data already loaded
    } else {
      _isLoading = true;
    }

    _isLoadingDashboard = true; // Set loading guard
    _errorMessage = null;
    notifyListeners();

    try {
      // Get location coordinates from selected address or current location
      final (lat, lng) = locationCoordinates;

      // Load both old format and new dynamic sections
      final futures = await Future.wait([
        _dashboardService.getHomepageData(
          latitude: lat,
          longitude: lng,
          type:
              _deliveryMode == DeliveryMode.delivery ? 'delivery' : 'takeaway',
        ),
        _dashboardService.getHomepageSections(
          latitude: lat,
          longitude: lng,
          type:
              _deliveryMode == DeliveryMode.delivery ? 'delivery' : 'takeaway',
        ),
      ]);

      final dashboardResponse = futures[0] as dynamic;
      final sectionsResponse = futures[1] as dynamic;

      if (dashboardResponse.success && dashboardResponse.data != null) {
        _dashboardData = dashboardResponse.data as DashboardModel;
        _categories = _dashboardData!.categories ?? [];
        _featuredRestaurants = _dashboardData!.featuredRestaurants ?? [];
        _nearbyRestaurants = _dashboardData!.nearbyRestaurants ?? [];
        _errorMessage = null;
      }

      if (sectionsResponse.success && sectionsResponse.data != null) {
        _sections = sectionsResponse.data as List<DashboardSection>;
      }

      if (!dashboardResponse.success && !sectionsResponse.success) {
        _errorMessage =
            dashboardResponse.message ?? 'Failed to load dashboard data';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while loading data: $e';
    } finally {
      _isLoading = false;
      _isLoadingDashboard = false; // Reset loading guard
      notifyListeners();
    }
  }

  Future<void> searchRestaurants({bool newSearch = true}) async {
    if (_searchQuery.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    if (newSearch) {
      _isSearching = true;
      _searchResults = [];
    } else {
      _isLoadingMore = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      // Get location coordinates from selected address or current location
      final (lat, lng) = locationCoordinates;

      final response = await _dashboardService.searchRestaurants(
        query: _searchQuery,
        latitude: lat,
        longitude: lng,
        categoryId: _selectedCategoryId,
        page: newSearch ? 1 : (_searchResults.length ~/ 20) + 1,
      );

      if (response.success && response.data != null) {
        if (newSearch) {
          _searchResults = response.data!;
        } else {
          _searchResults.addAll(response.data!);
        }
        _errorMessage = null;
      } else {
        _errorMessage = response.message ?? 'Search failed';
      }
    } catch (e) {
      _errorMessage = 'Search error: $e';
    } finally {
      _isSearching = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadRestaurantsByCategory(int categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get location coordinates from selected address or current location
      final (lat, lng) = locationCoordinates;

      final response = await _dashboardService.getRestaurantsByCategory(
        categoryId: categoryId,
        latitude: lat,
        longitude: lng,
      );

      if (response.success && response.data != null) {
        _nearbyRestaurants = response.data!;
        _errorMessage = null;
      } else {
        _errorMessage = response.message ?? 'Failed to load restaurants';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await loadDashboardData(refresh: true);
  }

  void clearSearchResults() {
    _searchResults = [];
    _searchQuery = '';
    _selectedCategoryId = null;
    notifyListeners();
  }
}
