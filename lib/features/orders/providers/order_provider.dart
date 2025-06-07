import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  // Orders lists
  List<OrderModel> _activeOrders = [];
  List<OrderModel> _pastOrders = [];
  List<OrderModel> _pendingOrders = [];

  // Current order details
  OrderModel? _currentOrderDetails;

  // Loading states
  bool _isLoadingActiveOrders = false;
  bool _isLoadingPastOrders = false;
  bool _isLoadingPendingOrders = false;
  bool _isLoadingOrderDetails = false;

  // Error states
  String? _activeOrdersError;
  String? _pastOrdersError;
  String? _pendingOrdersError;
  String? _orderDetailsError;

  // Pagination
  int _activeOrdersPage = 1;
  int _pastOrdersPage = 1;
  bool _hasMoreActiveOrders = true;
  bool _hasMorePastOrders = true;
  final int _ordersPerPage = 10;

  // Getters
  List<OrderModel> get activeOrders => _activeOrders;
  List<OrderModel> get pastOrders => _pastOrders;
  List<OrderModel> get pendingOrders => _pendingOrders;
  OrderModel? get currentOrderDetails => _currentOrderDetails;

  bool get isLoadingActiveOrders => _isLoadingActiveOrders;
  bool get isLoadingPastOrders => _isLoadingPastOrders;
  bool get isLoadingPendingOrders => _isLoadingPendingOrders;
  bool get isLoadingOrderDetails => _isLoadingOrderDetails;

  String? get activeOrdersError => _activeOrdersError;
  String? get pastOrdersError => _pastOrdersError;
  String? get pendingOrdersError => _pendingOrdersError;
  String? get orderDetailsError => _orderDetailsError;

  // Computed getters
  bool get hasActiveOrders => _activeOrders.isNotEmpty;
  bool get hasPastOrders => _pastOrders.isNotEmpty;
  bool get hasPendingOrders => _pendingOrders.isNotEmpty;

  int get totalActiveOrders => _activeOrders.length;
  int get totalPastOrders => _pastOrders.length;
  int get totalPendingOrders => _pendingOrders.length;

  /// Load active orders (confirmed, preparing, dispatched)
  Future<void> loadActiveOrders({bool showLoading = true}) async {
    if (showLoading) {
      _isLoadingActiveOrders = true;
      _activeOrdersError = null;
      notifyListeners();
    }

    // Reset pagination when loading fresh
    _activeOrdersPage = 1;
    _hasMoreActiveOrders = true;

    try {
      final response = await _orderService.getUserOrders(
        type: 'active',
        page: _activeOrdersPage,
        limit: _ordersPerPage,
      );

      if (response.success && response.data != null) {
        _activeOrders = response.data!;
        _hasMoreActiveOrders = response.data!.length >= _ordersPerPage;
        debugPrint('Loaded ${_activeOrders.length} active orders');
      } else {
        _activeOrdersError = response.message ?? 'Failed to load active orders';
        debugPrint('Error loading active orders: $_activeOrdersError');
      }
    } catch (e) {
      _activeOrdersError = 'Failed to load active orders: $e';
      debugPrint('Exception loading active orders: $e');
    } finally {
      if (showLoading) {
        _isLoadingActiveOrders = false;
      }
      notifyListeners();
    }
  }

  /// Load past orders (delivered, cancelled)
  Future<void> loadPastOrders({bool showLoading = true}) async {
    if (showLoading) {
      _isLoadingPastOrders = true;
      _pastOrdersError = null;
      notifyListeners();
    }

    // Reset pagination when loading fresh
    _pastOrdersPage = 1;
    _hasMorePastOrders = true;

    try {
      final response = await _orderService.getUserOrders(
        type: 'past',
        page: _pastOrdersPage,
        limit: _ordersPerPage,
      );

      if (response.success && response.data != null) {
        _pastOrders = response.data!;
        _hasMorePastOrders = response.data!.length >= _ordersPerPage;
        debugPrint('Loaded ${_pastOrders.length} past orders');
      } else {
        _pastOrdersError = response.message ?? 'Failed to load past orders';
        debugPrint('Error loading past orders: $_pastOrdersError');
      }
    } catch (e, stackTrace) {
      _pastOrdersError = 'Failed to load past orders: $e';
      debugPrint('Exception loading past orders: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (showLoading) {
        _isLoadingPastOrders = false;
      }
      notifyListeners();
    }
  }

  /// Load pending orders (newly placed, awaiting confirmation)
  Future<void> loadPendingOrders() async {
    _isLoadingPendingOrders = true;
    _pendingOrdersError = null;
    notifyListeners();

    try {
      final response = await _orderService.getUserOrders(type: 'pending');

      if (response.success && response.data != null) {
        _pendingOrders = response.data!;
        debugPrint('Loaded ${_pendingOrders.length} pending orders');
      } else {
        _pendingOrdersError =
            response.message ?? 'Failed to load pending orders';
        debugPrint('Error loading pending orders: $_pendingOrdersError');
      }
    } catch (e, stackTrace) {
      _pendingOrdersError = 'Failed to load pending orders: $e';
      debugPrint('Exception loading pending orders: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isLoadingPendingOrders = false;
      notifyListeners();
    }
  }

  /// Load all orders
  Future<void> loadAllOrders() async {
    await Future.wait([
      loadActiveOrders(),
      loadPastOrders(),
      loadPendingOrders(),
    ]);
  }

  /// Load order details by ID
  Future<void> loadOrderDetails({
    required int orderId,
    int? vendorId,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoadingOrderDetails = true;
      _orderDetailsError = null;
      _currentOrderDetails = null;
      notifyListeners();
    }

    try {
      debugPrint('=== Loading Order Details ===');
      debugPrint('Order ID: $orderId');
      debugPrint('Vendor ID: $vendorId');
      debugPrint('============================');

      final response = await _orderService.getOrderDetails(
        orderId: orderId,
        vendorId: vendorId,
      );

      if (response.success && response.data != null) {
        _currentOrderDetails = response.data!;
        debugPrint('Successfully loaded order details for order ID: $orderId');
        debugPrint(' order ID: ${response.data.toString()}');

        // Clear any previous error
        _orderDetailsError = null;
      } else {
        _orderDetailsError = response.message ?? 'Failed to load order details';
        debugPrint('Error loading order details: $_orderDetailsError');

        // If the error is about missing vendor_id, provide a helpful message
        if (_orderDetailsError!.contains('vendor_id') ||
            _orderDetailsError!.contains('non-object')) {
          _orderDetailsError =
              'Unable to load order details. Please try refreshing your orders list first.';
        }
      }
    } catch (e) {
      _orderDetailsError = 'Failed to load order details: $e';
      debugPrint('Exception loading order details: $e');
    } finally {
      if (showLoading) {
        _isLoadingOrderDetails = false;
      }
      notifyListeners();
    }
  }

  /// Find order by ID from cached orders
  OrderModel? findOrderById(int orderId) {
    // Check in active orders first
    try {
      return _activeOrders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      // Not found, continue
    }

    // Check in past orders
    try {
      return _pastOrders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      // Not found, continue
    }

    // Check in pending orders
    try {
      return _pendingOrders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      // Not found
    }

    return null;
  }

  /// Refresh specific order from server
  Future<void> refreshOrder(int orderId) async {
    await loadOrderDetails(orderId: orderId);

    // Update the order in cached lists if found
    if (_currentOrderDetails != null) {
      final order = _currentOrderDetails!;

      // Update in appropriate list based on status
      if (order.isPending) {
        final index = _pendingOrders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _pendingOrders[index] = order;
        }
      } else if (order.isActive) {
        final index = _activeOrders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _activeOrders[index] = order;
        }
      } else if (order.isPast) {
        final index = _pastOrders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _pastOrders[index] = order;
        }
      }

      notifyListeners();
    }
  }

  /// Get order status display information
  Map<String, dynamic> getOrderStatusInfo(int statusId) {
    switch (statusId) {
      case 1:
        return {
          'name': 'Pending',
          'description': 'Order is waiting for confirmation',
          'color': 0xFFFF9800, // Orange
          'icon': 'schedule',
        };
      case 2:
        return {
          'name': 'Confirmed',
          'description': 'Order has been confirmed by restaurant',
          'color': 0xFF2196F3, // Blue
          'icon': 'check_circle',
        };
      case 3:
        return {
          'name': 'Cancelled',
          'description': 'Order has been cancelled',
          'color': 0xFFF44336, // Red
          'icon': 'cancel',
        };
      case 4:
        return {
          'name': 'Preparing',
          'description': 'Restaurant is preparing your order',
          'color': 0xFFFF5722, // Deep Orange
          'icon': 'restaurant',
        };
      case 5:
        return {
          'name': 'Ready',
          'description': 'Order is ready for pickup/delivery',
          'color': 0xFF9C27B0, // Purple
          'icon': 'done_all',
        };
      case 6:
        return {
          'name': 'Delivered',
          'description': 'Order has been delivered successfully',
          'color': 0xFF4CAF50, // Green
          'icon': 'verified',
        };
      default:
        return {
          'name': 'Unknown',
          'description': 'Order status unknown',
          'color': 0xFF9E9E9E, // Grey
          'icon': 'help',
        };
    }
  }

  /// Load more active orders (pagination)
  Future<void> loadMoreActiveOrders() async {
    if (!_hasMoreActiveOrders || _isLoadingActiveOrders) return;

    _activeOrdersPage++;

    try {
      final response = await _orderService.getUserOrders(
        type: 'active',
        page: _activeOrdersPage,
        limit: _ordersPerPage,
      );

      if (response.success && response.data != null) {
        if (response.data!.isEmpty) {
          _hasMoreActiveOrders = false;
        } else {
          _activeOrders.addAll(response.data!);
          _hasMoreActiveOrders = response.data!.length >= _ordersPerPage;
        }
        debugPrint(
            'Loaded ${response.data!.length} more active orders. Total: ${_activeOrders.length}');
      }
    } catch (e) {
      debugPrint('Error loading more active orders: $e');
      _activeOrdersPage--; // Revert page on error
    }

    notifyListeners();
  }

  /// Load more past orders (pagination)
  Future<void> loadMorePastOrders() async {
    if (!_hasMorePastOrders || _isLoadingPastOrders) return;

    _pastOrdersPage++;

    try {
      final response = await _orderService.getUserOrders(
        type: 'past',
        page: _pastOrdersPage,
        limit: _ordersPerPage,
      );

      if (response.success && response.data != null) {
        if (response.data!.isEmpty) {
          _hasMorePastOrders = false;
        } else {
          _pastOrders.addAll(response.data!);
          _hasMorePastOrders = response.data!.length >= _ordersPerPage;
        }
        debugPrint(
            'Loaded ${response.data!.length} more past orders. Total: ${_pastOrders.length}');
      }
    } catch (e) {
      debugPrint('Error loading more past orders: $e');
      _pastOrdersPage--; // Revert page on error
    }

    notifyListeners();
  }

  /// Clear all cached data
  void clearOrders() {
    _activeOrders.clear();
    _pastOrders.clear();
    _pendingOrders.clear();
    _currentOrderDetails = null;

    _activeOrdersError = null;
    _pastOrdersError = null;
    _pendingOrdersError = null;
    _orderDetailsError = null;

    notifyListeners();
  }
}
