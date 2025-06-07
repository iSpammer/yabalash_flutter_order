import 'package:flutter/foundation.dart';

/// Debug logger for tracking product stock issues
/// This helps identify why products show as inactive when they should be active
class StockDebugLogger {
  static bool _enabled = kDebugMode; // Only log in debug mode
  
  static void enable() => _enabled = true;
  static void disable() => _enabled = false;
  
  /// Log product stock evaluation
  static void logProductStock({
    required int productId,
    required String productName,
    required bool isActive,
    required bool hasInventory,
    required int stockQuantity,
    required bool sellWhenOutOfStock,
    required int? typeId,
    required bool finalIsInStock,
  }) {
    if (!_enabled) return;
    
    debugPrint('🔍 STOCK CHECK: $productName (ID: $productId)');
    debugPrint('   Active: $isActive, Has Inventory: $hasInventory');
    debugPrint('   Stock: $stockQuantity, Type ID: $typeId');
    debugPrint('   Sell When Out: $sellWhenOutOfStock');
    debugPrint('   ✓ Final Result: ${finalIsInStock ? "IN STOCK" : "OUT OF STOCK"}');
    
    // Log the reason for the result
    if (finalIsInStock) {
      if (!hasInventory) {
        debugPrint('   ↳ Reason: Inventory not tracked (has_inventory = 0)');
      } else if (stockQuantity > 0) {
        debugPrint('   ↳ Reason: Has stock available ($stockQuantity)');
      } else if (typeId == 8) {
        debugPrint('   ↳ Reason: Special service product (typeId = 8)');
      } else if (sellWhenOutOfStock) {
        debugPrint('   ↳ Reason: Allows backorders');
      }
    } else {
      debugPrint('   ↳ Reason: All availability conditions failed');
    }
    debugPrint('');
  }
  
  /// Log API response parsing
  static void logApiParsing({
    required Map<String, dynamic> json,
    required String field,
    required dynamic rawValue,
    required dynamic parsedValue,
  }) {
    if (!_enabled) return;
    
    debugPrint('📥 API PARSE: $field');
    debugPrint('   Raw value: $rawValue (${rawValue.runtimeType})');
    debugPrint('   Parsed as: $parsedValue (${parsedValue.runtimeType})');
    
    // Warn about potential parsing issues
    if (field == 'has_inventory') {
      if (rawValue is String && rawValue == '0' && parsedValue != false) {
        debugPrint('   ⚠️ WARNING: String "0" not parsed as false!');
      }
      if (rawValue is String && rawValue == '1' && parsedValue != true) {
        debugPrint('   ⚠️ WARNING: String "1" not parsed as true!');
      }
    }
  }
  
  /// Log product list summary
  static void logProductListSummary({
    required List<dynamic> products,
    required int totalCount,
    required int inStockCount,
    required int outOfStockCount,
  }) {
    if (!_enabled) return;
    
    debugPrint('📊 PRODUCT LIST SUMMARY');
    debugPrint('   Total: $totalCount');
    debugPrint('   In Stock: $inStockCount (${(inStockCount / totalCount * 100).toStringAsFixed(1)}%)');
    debugPrint('   Out of Stock: $outOfStockCount (${(outOfStockCount / totalCount * 100).toStringAsFixed(1)}%)');
    
    // List out of stock products for investigation
    if (outOfStockCount > 0) {
      debugPrint('\n   Out of stock products:');
      for (final product in products.where((p) => !p.isInStock)) {
        debugPrint('   - ${product.name} (ID: ${product.id})');
      }
    }
    debugPrint('');
  }
  
  /// Compare with React Native logic
  static void compareWithReactNative({
    required int productId,
    required String productName,
    required bool flutterResult,
    required Map<String, dynamic> conditions,
  }) {
    if (!_enabled) return;
    
    debugPrint('🔄 REACT NATIVE COMPARISON: $productName');
    debugPrint('   Flutter says: ${flutterResult ? "IN STOCK" : "OUT OF STOCK"}');
    
    // Check React Native conditions from ProductsCompTwo.js line 124-127
    final hasInventory = conditions['has_inventory'] ?? 1;
    final variantQuantity = conditions['variant_quantity'] ?? 0;
    final typeId = conditions['type_id'] ?? 0;
    final businessType = conditions['business_type'] ?? '';
    
    final reactNativeResult = hasInventory == 0 || 
                             variantQuantity > 0 || 
                             typeId == 8 || 
                             businessType == 'laundry';
    
    debugPrint('   React Native would say: ${reactNativeResult ? "IN STOCK" : "OUT OF STOCK"}');
    
    if (flutterResult != reactNativeResult) {
      debugPrint('   ⚠️ MISMATCH DETECTED!');
      debugPrint('   Conditions: has_inventory=$hasInventory, variant_qty=$variantQuantity, typeId=$typeId');
    }
    debugPrint('');
  }
}