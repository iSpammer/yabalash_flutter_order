import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../widgets/order_card_vendor.dart';
import '../widgets/cancel_order_dialog.dart';
import '../widgets/repeat_order_dialog.dart';
import '../widgets/return_order_modal.dart';
import '../services/order_service.dart';
import '../../cart/providers/cart_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _activeOrdersTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add tab listener
    _tabController.addListener(_handleTabChange);
    
    // Setup scroll listener for pagination
    _scrollController.addListener(_handleScroll);
    
    // Load orders when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrdersForCurrentTab();
    });
    
    // Start polling for active orders
    _startActiveOrdersPolling();
  }

  @override
  void dispose() {
    _activeOrdersTimer?.cancel();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    
    // Cancel timer when switching away from active tab
    if (_tabController.index != 0) {
      _activeOrdersTimer?.cancel();
    } else {
      _startActiveOrdersPolling();
    }
    
    // Load orders for new tab
    _loadOrdersForCurrentTab();
  }
  
  void _loadOrdersForCurrentTab() {
    final orderProvider = context.read<OrderProvider>();
    if (_tabController.index == 0) {
      orderProvider.loadActiveOrders();
    } else {
      orderProvider.loadPastOrders();
    }
  }
  
  void _startActiveOrdersPolling() {
    // Only poll if on active orders tab
    if (_tabController.index != 0) return;
    
    _activeOrdersTimer?.cancel();
    _activeOrdersTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _tabController.index == 0) {
        // Silent refresh - don't show loading indicator
        context.read<OrderProvider>().loadActiveOrders(showLoading: false);
      }
    });
  }
  
  void _handleScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      _loadMore();
    }
  }
  
  void _loadMore() {
    if (_isLoadingMore) return;
    
    setState(() => _isLoadingMore = true);
    
    final orderProvider = context.read<OrderProvider>();
    final future = _tabController.index == 0
        ? orderProvider.loadMoreActiveOrders()
        : orderProvider.loadMorePastOrders();
        
    future.whenComplete(() {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Active Orders'),
                Tab(text: 'Past Orders'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildActiveOrdersTab(orderProvider),
              _buildPastOrdersTab(orderProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveOrdersTab(OrderProvider orderProvider) {
    return RefreshIndicator(
      onRefresh: () => orderProvider.loadActiveOrders(),
      child: _buildOrdersList(
        orders: orderProvider.activeOrders,
        isLoading: orderProvider.isLoadingActiveOrders,
        error: orderProvider.activeOrdersError,
        emptyMessage: 'No active orders',
        emptyDescription: 'Your active orders will appear here when you place an order.',
        emptyIcon: Icons.shopping_bag_outlined,
        showRepeatButton: false,
      ),
    );
  }

  Widget _buildPastOrdersTab(OrderProvider orderProvider) {
    return RefreshIndicator(
      onRefresh: () => orderProvider.loadPastOrders(),
      child: _buildOrdersList(
        orders: orderProvider.pastOrders,
        isLoading: orderProvider.isLoadingPastOrders,
        error: orderProvider.pastOrdersError,
        emptyMessage: 'No past orders',
        emptyDescription: 'Your order history will appear here after you complete orders.',
        emptyIcon: Icons.history,
        showRepeatButton: true,
      ),
    );
  }


  Widget _buildOrdersList({
    required List<OrderModel> orders,
    required bool isLoading,
    required String? error,
    required String emptyMessage,
    required String emptyDescription,
    required IconData emptyIcon,
    required bool showRepeatButton,
  }) {
    if (isLoading && orders.isEmpty) {
      return _buildLoadingView();
    }

    if (error != null && orders.isEmpty) {
      return _buildErrorView(error);
    }

    if (orders.isEmpty) {
      return _buildEmptyView(emptyMessage, emptyDescription, emptyIcon);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 20.h),
      itemCount: orders.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == orders.length) {
          return _buildLoadingMoreIndicator();
        }
        
        final order = orders[index];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: OrderCardVendor(
            order: order,
            onTap: () => _navigateToOrderDetails(order),
            showRepeatOrderButton: showRepeatButton,
            onRepeatOrder: showRepeatButton ? () => _handleRepeatOrder(order) : null,
            onReturnOrder: showRepeatButton ? () => _handleReturnOrder(order) : null,
            onReplaceOrder: showRepeatButton ? () => _handleReplaceOrder(order) : null,
            onCancelOrder: !showRepeatButton ? () => _handleCancelOrder(order) : null,
            etaTime: order.eta,
            isDarkMode: Theme.of(context).brightness == Brightness.dark,
          ),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            'Loading orders...',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
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
            ElevatedButton(
              onPressed: () => _retryLoading(),
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(16.h),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyView(String message, String description, IconData icon) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              description,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToOrderDetails(OrderModel order) {
    context.push('/order/details/${order.id}');
  }
  
  void _handleRepeatOrder(OrderModel order) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => RepeatOrderDialog(
        order: order,
        onConfirm: () {
          Navigator.of(context).pop(true);
        },
      ),
    );
    
    if (confirm != true) return;
    
    try {
      // Get cart provider before async gap
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final router = GoRouter.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // First ensure cart is loaded
      await cartProvider.loadCart();
      
      // Get cart ID - if no cart exists, it will be 0 or null
      final cartId = cartProvider.cartData?.id ?? 0;
      
      // Call repeat order API
      final orderService = OrderService();
      final response = await orderService.repeatOrder(
        orderVendorId: order.id,
        cartId: cartId,
      );
      
      if (response.success) {
        // Reload cart to get updated items
        await cartProvider.loadCart();
        
        if (!mounted) return;
        
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Items added to cart successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to cart
        router.go('/cart');
      } else {
        if (!mounted) return;
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to repeat order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _handleReturnOrder(OrderModel order) async {
    // Get return order details
    final orderService = OrderService();
    final response = await orderService.getReturnOrderDetails(
      orderId: order.orderId ?? order.id,
      vendorId: order.vendorId ?? order.vendor?.id ?? 0,
    );
    
    if (!response.success || response.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load order details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final products = _getOrderProducts(order);
    
    // Show return modal
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReturnOrderModal(
        order: order,
        products: products,
        isReplace: false,
        onConfirm: (productIds) {
          // Navigate to return order screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Return order request submitted'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh orders
          _loadOrdersForCurrentTab();
        },
      ),
    );
  }
  
  void _handleReplaceOrder(OrderModel order) async {
    // Get products for replace
    final orderService = OrderService();
    final response = await orderService.getProductsForReplace(
      orderId: order.orderId ?? order.id,
      vendorId: order.vendorId ?? order.vendor?.id ?? 0,
    );
    
    if (!response.success || response.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load products'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final products = _getOrderProducts(order);
    
    // Show replace modal
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReturnOrderModal(
        order: order,
        products: products,
        isReplace: true,
        onConfirm: (productIds) {
          // Navigate to replace order screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Replace order request submitted'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh orders
          _loadOrdersForCurrentTab();
        },
      ),
    );
  }
  
  List<OrderProductModel> _getOrderProducts(OrderModel order) {
    // Get products from vendors array if available, otherwise from products array
    if (order.vendors?.isNotEmpty == true) {
      final vendor = order.vendors!.first;
      return vendor.products ?? [];
    }
    return order.products ?? [];
  }
  
  void _handleCancelOrder(OrderModel order) async {
    // Load cancellation reasons
    final orderService = OrderService();
    final reasonsResponse = await orderService.getCancellationReasons();
    
    if (!reasonsResponse.success || reasonsResponse.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load cancellation reasons'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final reasons = reasonsResponse.data!
        .map((json) => CancelReason.fromJson(json))
        .toList();
    
    // Show cancel dialog
    await showDialog(
      context: context,
      builder: (context) => CancelOrderDialog(
        reasons: reasons,
        onConfirm: (reasonId, customReason) async {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
          
          // Get the correct order and vendor IDs
          // The order.id is actually the order_vendor_id, we need the actual order_id
          int actualOrderId = order.orderId ?? order.id;
          int actualVendorId = order.vendorId ?? 0;
          
          // If we have vendors array, get the vendor_id from there
          if (order.vendors?.isNotEmpty == true) {
            final firstVendor = order.vendors!.first;
            // Use the vendor_id from the vendor
            actualVendorId = firstVendor.vendorId;
          } else if (order.vendor != null) {
            actualVendorId = order.vendor!.id;
          }
          
          // Call cancel order API - match React Native exactly
          final response = await orderService.cancelOrder(
            orderId: actualOrderId,
            vendorId: actualVendorId,
            rejectReason: customReason ?? '',
            cancelReasonId: reasonId == 8 ? null : reasonId, // Only send if not "Other"
            statusOptionId: order.orderStatus?.currentStatus?.id ?? order.statusId,
          );
          
          // Hide loading
          if (mounted) {
            Navigator.of(context).pop();
          }
          
          if (!mounted) return;
          
          if (response.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order cancelled successfully'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Refresh orders
            _loadOrdersForCurrentTab();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message ?? 'Failed to cancel order'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _retryLoading() {
    final currentIndex = _tabController.index;
    final orderProvider = context.read<OrderProvider>();
    
    switch (currentIndex) {
      case 0:
        orderProvider.loadActiveOrders();
        break;
      case 1:
        orderProvider.loadPastOrders();
        break;
    }
  }
}