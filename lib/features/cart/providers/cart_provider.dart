import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../services/product_variant_service.dart';
import '../../restaurants/models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  final ProductVariantService _variantService = ProductVariantService();
  
  CartModel? _cartData;
  bool _isLoading = false;
  String? _errorMessage;
  int _itemCount = 0;
  double _totalAmount = 0.0;
  int? _currentVendorId;
  
  // Selected options for checkout
  int? _selectedAddressId;
  int? _selectedPaymentMethodId;
  String? _selectedPaymentMethodTitle;
  double? _tipAmount;
  String _scheduleType = 'now';
  DateTime? _scheduledDateTime;
  
  // Getters
  CartModel? get cartData => _cartData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _itemCount;
  double get totalAmount => _totalAmount;
  int? get currentVendorId => _currentVendorId;
  int? get selectedAddressId => _selectedAddressId;
  int? get selectedPaymentMethodId => _selectedPaymentMethodId;
  double? get tipAmount => _tipAmount;
  String get scheduleType => _scheduleType;
  DateTime? get scheduledDateTime => _scheduledDateTime;
  
  // Check if cart has items
  bool get hasItems => _itemCount > 0;
  
  // Check if cart has items from a specific vendor
  bool hasItemsFromDifferentVendor(int vendorId) {
    if (_cartData == null || _cartData!.products.isEmpty) return false;
    
    // Check if any vendor in cart is different from the provided vendorId
    for (var vendor in _cartData!.products) {
      if (vendor.vendorId != null && vendor.vendorId != vendorId) {
        return true;
      }
    }
    return false;
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Get vendor-specific data
  CartVendorItem? getVendorCart(int vendorId) {
    return _cartData?.products.firstWhere(
      (vendor) => vendor.vendorId == vendorId,
      orElse: () => CartVendorItem(vendorProducts: []),
    );
  }
  
  // Get quantity for a specific product
  int getQuantityForProduct(ProductModel product, {int? variantId}) {
    if (_cartData == null) return 0;
    
    for (var vendor in _cartData!.products) {
      for (var cartProduct in vendor.vendorProducts) {
        if (cartProduct.product?.id == product.id) {
          // If variantId is specified, check that too
          if (variantId != null) {
            if (cartProduct.variants?.id == variantId) {
              return cartProduct.quantity ?? 0;
            }
          } else if (cartProduct.variants == null) {
            // No variant specified and cart item has no variant
            return cartProduct.quantity ?? 0;
          }
        }
      }
    }
    return 0;
  }
  
  // Get cart item for a specific product
  CartProductItem? getCartItem(int productId, {int? variantId}) {
    if (_cartData == null) return null;
    
    for (var vendor in _cartData!.products) {
      for (var cartProduct in vendor.vendorProducts) {
        if (cartProduct.product?.id == productId) {
          // If variantId is specified, check that too
          if (variantId != null) {
            if (cartProduct.variants?.id == variantId) {
              return cartProduct;
            }
          } else if (cartProduct.variants == null) {
            // No variant specified and cart item has no variant
            return cartProduct;
          }
        }
      }
    }
    return null;
  }
  
  // Calculate totals
  void _calculateTotals() {
    _itemCount = 0;
    _totalAmount = 0.0;
    
    if (_cartData != null) {
      for (var vendor in _cartData!.products) {
        for (var product in vendor.vendorProducts) {
          _itemCount += product.quantity ?? 0;
        }
      }
      _totalAmount = _cartData!.totalPayableAmount ?? 0.0;
    }
  }
  
  // Load cart data
  Future<void> loadCart({String type = 'delivery'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _cartService.getCartDetail(type: type);
      
      if (response.success) {
        _cartData = response.data;
        _calculateTotals();
        
        // Set current vendor ID if cart has items
        if (_cartData!.products.isNotEmpty) {
          _currentVendorId = _cartData!.products.first.vendorId;
        }
        
        // Set schedule type from cart data
        if (_cartData!.scheduleType != null) {
          _scheduleType = _cartData!.scheduleType!;
          if (_scheduleType == 'schedule' && _cartData!.scheduledDateTime != null) {
            _scheduledDateTime = DateTime.tryParse(_cartData!.scheduledDateTime!);
          }
        }
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load cart';
      debugPrint('Error loading cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add item to cart
  Future<bool> addToCart({
    required ProductModel product,
    required int quantity,
    int? variantId,
    List<Map<String, dynamic>>? addons,
    String type = 'delivery',
    bool skipLoadCart = false, // Add flag to skip cart reload
  }) async {
    // Don't automatically clear cart here - let the UI handle vendor conflicts
    // if (_currentVendorId != null && _currentVendorId != product.vendorId) {
    //   await clearCart();
    // }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      String sku = product.sku ?? '';
      
      debugPrint('=== CART PROVIDER ADD TO CART ===');
      debugPrint('Product: ${product.name} (ID: ${product.id})');
      debugPrint('Product SKU: ${product.sku}');
      debugPrint('Has Variants: ${product.hasVariants}');
      debugPrint('Variant ID passed: $variantId');
      
      // If no product SKU exists, use fallback (this shouldn't happen in production)
      if (sku.isEmpty) {
        debugPrint('Warning: Product ${product.id} has no SKU, using fallback');
        sku = 'SKU${product.id}';
      }

      // Step 1: Get product variant details to get the actual variant ID
      debugPrint('Step 1: Fetching product variant details for SKU: $sku');
      final variantDetailsResponse = await _variantService.getProductVariantDetails(sku);
      
      if (!variantDetailsResponse.success || variantDetailsResponse.data == null) {
        _errorMessage = variantDetailsResponse.message ?? 'Failed to load product details';
        notifyListeners();
        return false;
      }

      final variantDetails = variantDetailsResponse.data!;
      
      // Get the variant ID from the API response
      int? actualVariantId;
      if (variantDetails.variants.isNotEmpty) {
        // If a specific variant was requested and exists, use it
        if (variantId != null) {
          final matchingVariant = variantDetails.variants.firstWhere(
            (v) => v.id == variantId,
            orElse: () => variantDetails.variants.first,
          );
          actualVariantId = matchingVariant.id;
        } else {
          // Otherwise use the first variant (even for products with has_variant = 0)
          actualVariantId = variantDetails.variants.first.id;
        }
        debugPrint('Using variant ID from API: $actualVariantId');
      } else {
        debugPrint('WARNING: No variants found in API response');
        _errorMessage = 'Product configuration error - no variants available';
        notifyListeners();
        return false;
      }

      // Check if product has required addons
      if (addons == null || addons.isEmpty) {
        for (final addonSet in variantDetails.addonSets) {
          if (addonSet.minSelect > 0) {
            _errorMessage = 'Please select ${addonSet.title}';
            notifyListeners();
            return false;
          }
        }
      }

      // Step 2: Add to cart with the proper variant ID
      debugPrint('Step 2: Adding to cart with variant ID: $actualVariantId');
      final response = await _cartService.addToCart(
        sku: sku,
        quantity: quantity,
        productId: product.id,
        productVariantId: actualVariantId, // Use the variant ID from API
        addons: addons,
        type: type,
      );
      
      if (response.success) {
        // Instead of trying to parse the response data directly,
        // reload the cart to get the updated data
        if (!skipLoadCart) {
          await loadCart(type: type);
        }
        _currentVendorId = product.vendorId;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        
        // Check if this is a vendor conflict error
        if (_errorMessage != null && 
            (_errorMessage!.toLowerCase().contains('vendor') || 
             _errorMessage!.toLowerCase().contains('another vendor') ||
             _errorMessage!.toLowerCase().contains('existing items'))) {
          // Keep the original error message but also mark it as vendor conflict
          debugPrint('Vendor conflict detected: $_errorMessage');
          // The UI will check for vendor-related keywords in the message
        }
        
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to add to cart';
      debugPrint('Error adding to cart: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update item quantity
  Future<bool> updateQuantity({
    required int cartProductId,
    required int quantity,
    String type = 'delivery',
  }) async {
    if (_cartData == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _cartService.updateCartQuantity(
        cartId: _cartData!.id!,
        cartProductId: cartProductId,
        quantity: quantity,
        type: type,
      );
      
      if (response.success) {
        _cartData = response.data;
        _calculateTotals();
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update quantity';
      debugPrint('Error updating quantity: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Remove item from cart
  Future<bool> removeFromCart({
    required int cartProductId,
    String type = 'delivery',
  }) async {
    if (_cartData == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _cartService.removeFromCart(
        cartId: _cartData!.id!,
        cartProductId: cartProductId,
        type: type,
      );
      
      if (response.success) {
        _cartData = response.data;
        _calculateTotals();
        
        // Clear vendor ID if cart is empty
        if (_itemCount == 0) {
          _currentVendorId = null;
        }
        
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to remove from cart';
      debugPrint('Error removing from cart: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear entire cart
  Future<bool> clearCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      debugPrint('=== CLEAR CART START ===');
      final response = await _cartService.clearCart();
      
      debugPrint('Cart clear response: success=${response.success}, message="${response.message}"');
      
      if (response.success) {
        debugPrint('✅ Cart clear API call successful');
        
        // Clear all cart-related state IMMEDIATELY
        _cartData = null;
        _itemCount = 0;
        _totalAmount = 0.0;
        _currentVendorId = null;
        _tipAmount = null;
        _selectedAddressId = null;
        _selectedPaymentMethodId = null;
        _selectedPaymentMethodTitle = null;
        _scheduleType = 'now';
        _scheduledDateTime = null;
        _errorMessage = null;
        
        // Force an immediate state update
        _isLoading = false;
        notifyListeners();
        
        // Wait longer for server to fully process the clear operation
        debugPrint('Waiting for server to process cart clear...');
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Verify cart is empty by reloading
        debugPrint('Reloading cart to verify it is empty...');
        await loadCart();
        
        // Double check cart is actually empty
        if (_itemCount > 0 || (_cartData?.products.isNotEmpty ?? false)) {
          debugPrint('ERROR: Cart still has ${_itemCount} items after clearing!');
          debugPrint('Cart data: ${_cartData?.toJson()}');
          _errorMessage = 'Cart clearing failed - items still present';
          notifyListeners();
          return false;
        }
        
        debugPrint('✅ Cart successfully cleared and verified empty');
        return true;
      } else {
        debugPrint('❌ Cart clear API call failed: ${response.message}');
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to clear cart';
      debugPrint('❌ Error clearing cart: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Apply promo code
  Future<bool> applyPromoCode({
    required int vendorId,
    required String promoCode,
  }) async {
    if (_cartData == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _cartService.applyPromoCode(
        vendorId: vendorId,
        cartId: _cartData!.id!,
        promoCode: promoCode,
      );
      
      if (response.success) {
        _cartData = response.data;
        _calculateTotals();
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to apply promo code';
      debugPrint('Error applying promo code: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Remove promo code
  Future<bool> removePromoCode({
    required int vendorId,
    required int couponId,
  }) async {
    if (_cartData == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _cartService.removePromoCode(
        vendorId: vendorId,
        cartId: _cartData!.id!,
        couponId: couponId,
      );
      
      if (response.success) {
        _cartData = response.data;
        _calculateTotals();
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to remove promo code';
      debugPrint('Error removing promo code: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Set delivery address
  void setDeliveryAddress(int addressId) {
    _selectedAddressId = addressId;
    notifyListeners();
  }
  
  // Set payment method
  void setPaymentMethod(int paymentMethodId) {
    _selectedPaymentMethodId = paymentMethodId;
    notifyListeners();
  }
  
  // Set selected payment method with title
  void setSelectedPaymentMethod(int paymentMethodId, String title) {
    _selectedPaymentMethodId = paymentMethodId;
    _selectedPaymentMethodTitle = title;
    notifyListeners();
  }
  
  // Set tip amount
  void setTipAmount(double? amount) {
    _tipAmount = amount;
    notifyListeners();
  }
  
  // Set schedule type
  Future<bool> setScheduleType(String type, {DateTime? scheduledDateTime}) async {
    _scheduleType = type;
    _scheduledDateTime = scheduledDateTime;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _cartService.scheduleOrder(
        taskType: type,
        scheduledDateTime: scheduledDateTime,
      );
      
      if (response.success) {
        _cartData = response.data;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to schedule order';
      debugPrint('Error scheduling order: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get quantity of a specific product in cart
  int getProductQuantity(int productId, {int? variantId}) {
    if (_cartData == null) return 0;
    
    int quantity = 0;
    for (var vendor in _cartData!.products) {
      for (var item in vendor.vendorProducts) {
        if (item.product?.id == productId) {
          if (variantId == null || item.variants?.id == variantId) {
            quantity += item.quantity ?? 0;
          }
        }
      }
    }
    
    return quantity;
  }
  
  
  // Add item helper for product card
  Future<void> addItem(ProductModel product, {int? variantId, List<Map<String, dynamic>>? addons}) async {
    await addToCart(
      product: product,
      quantity: 1,
      variantId: variantId,
      addons: addons,
    );
  }
  
  // Increment item helper for product card
  Future<void> incrementItem(ProductModel product, {int? variantId, List<String>? addonIds}) async {
    final currentQuantity = getProductQuantity(product.id ?? 0, variantId: variantId);
    final cartItem = getCartItem(product.id ?? 0, variantId: variantId);
    
    if (cartItem != null) {
      await updateQuantity(
        cartProductId: cartItem.id!,
        quantity: currentQuantity + 1,
      );
    } else {
      await addToCart(
        product: product,
        quantity: 1,
        variantId: variantId,
      );
    }
  }
  
  // Decrement item helper for product card
  Future<void> decrementItem(ProductModel product, {int? variantId, List<String>? addonIds}) async {
    final currentQuantity = getProductQuantity(product.id ?? 0, variantId: variantId);
    final cartItem = getCartItem(product.id ?? 0, variantId: variantId);
    
    if (cartItem != null && currentQuantity > 0) {
      if (currentQuantity == 1) {
        await removeFromCart(cartProductId: cartItem.id!);
      } else {
        await updateQuantity(
          cartProductId: cartItem.id!,
          quantity: currentQuantity - 1,
        );
      }
    }
  }
  
  // Check if product is in cart
  bool isProductInCart(int productId, {int? variantId}) {
    return getProductQuantity(productId, variantId: variantId) > 0;
  }
  
  
  // Check if cart meets minimum order amount
  bool meetsMinimumOrder() {
    if (_cartData == null) return true;
    
    final minimumAmount = _cartData!.minimumOrderAmount ?? 0;
    final currentAmount = _cartData!.totalPayableAmount ?? 0;
    
    return currentAmount >= minimumAmount;
  }
  
  // Get remaining amount to meet minimum order
  double getRemainingMinimumAmount() {
    if (_cartData == null) return 0;
    
    final minimumAmount = _cartData!.minimumOrderAmount ?? 0;
    final currentAmount = _cartData!.totalPayableAmount ?? 0;
    
    if (currentAmount >= minimumAmount) return 0;
    
    return minimumAmount - currentAmount;
  }

  // Get product variant details for addon selection
  Future<ProductVariantDetails?> getProductVariantDetails(String sku) async {
    try {
      final response = await _variantService.getProductVariantDetails(sku);
      if (response.success && response.data != null) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Error getting product variant details: $e');
    }
    return null;
  }

  // Get promo code list for a vendor
  Future<List<Map<String, dynamic>>> getPromoCodeList(int vendorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartService.getPromoCodeList(vendorId: vendorId);
      
      if (response.success) {
        _isLoading = false;
        notifyListeners();
        return response.data ?? [];
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      _errorMessage = 'An error occurred while fetching promo codes';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Check vendor slots for delivery/pickup
  Future<Map<String, dynamic>?> checkVendorSlots({
    required int vendorId,
    dynamic delivery = 1,
    String? date,
    int? cartId,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartService.checkVendorSlots(
        vendorId: vendorId,
        delivery: delivery,
        date: date,
        cartId: cartId ?? _cartData?.id,
        latitude: latitude,
        longitude: longitude,
      );
      
      if (response.success) {
        _isLoading = false;
        notifyListeners();
        return response.data;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'An error occurred while checking vendor slots';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}