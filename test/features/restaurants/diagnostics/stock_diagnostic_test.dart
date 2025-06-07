import 'package:flutter_test/flutter_test.dart';
import 'package:yabalash_fe_flutter/features/restaurants/models/product_model.dart';

void main() {
  group('Product Stock Diagnostic Tests', () {
    // Helper function to diagnose why a product might show as out of stock
    void diagnoseProduct(ProductModel product) {
      print('\n=== PRODUCT DIAGNOSTIC: ${product.name} (ID: ${product.id}) ===');
      print('isActive: ${product.isActive}');
      print('hasInventory: ${product.hasInventory}');
      print('stockQuantity: ${product.stockQuantity}');
      print('productTotalQuantity: ${product.productTotalQuantity}');
      print('sellWhenOutOfStock: ${product.sellWhenOutOfStock}');
      print('typeId: ${product.typeId}');
      print('hasVariants: ${product.hasVariants}');
      
      print('\nStock Check Conditions:');
      print('1. has_inventory == 0? ${!product.hasInventory} ✓ Makes product available');
      print('2. productTotalQuantity > 0? ${product.productTotalQuantity > 0} ✓ Makes product available');
      print('3. typeId == 8? ${product.typeId == 8} ✓ Makes product available');
      print('4. sell_when_out_of_stock? ${product.sellWhenOutOfStock} ✓ Makes product available');
      
      print('\nFINAL RESULT: isInStock = ${product.isInStock}');
      
      if (!product.isInStock) {
        print('\n❌ PRODUCT IS OUT OF STOCK because:');
        print('   - Inventory is tracked (has_inventory = ${product.hasInventory})');
        print('   - No stock available (quantity = ${product.stockQuantity})');
        print('   - Not a special service (typeId = ${product.typeId})');
        print('   - Backorders not allowed (sell_when_out_of_stock = ${product.sellWhenOutOfStock})');
      } else {
        print('\n✅ PRODUCT IS IN STOCK because:');
        if (!product.hasInventory) print('   - Inventory is not tracked');
        if (product.productTotalQuantity > 0) print('   - Has stock available');
        if (product.typeId == 8) print('   - Is a special service product');
        if (product.sellWhenOutOfStock) print('   - Allows backorders');
      }
      print('=========================================\n');
    }

    test('diagnose example products that users report as showing incorrectly', () {
      // Example 1: Product that should be available (like in React Native) but shows as unavailable
      final product1 = ProductModel(
        id: 101,
        name: 'Pizza Special',
        price: 15.99,
        vendorId: 1,
        categoryId: 5,
        isActive: false, // Inactive
        hasInventory: false, // has_inventory = 0 (not tracked)
        sellWhenOutOfStock: false,
        stockQuantity: 0,
      );
      
      diagnoseProduct(product1);
      expect(product1.isInStock, true, 
        reason: 'This product should be available because has_inventory = 0');

      // Example 2: Service product with no stock
      final product2 = ProductModel(
        id: 102,
        name: 'Delivery Service',
        price: 5.00,
        vendorId: 1,
        categoryId: 8,
        isActive: true,
        hasInventory: true,
        sellWhenOutOfStock: false,
        stockQuantity: 0,
        typeId: 8, // Service type
      );
      
      diagnoseProduct(product2);
      expect(product2.isInStock, true, 
        reason: 'Service products (typeId=8) should always be available');

      // Example 3: Regular product that should be out of stock
      final product3 = ProductModel(
        id: 103,
        name: 'Limited Edition Item',
        price: 25.00,
        vendorId: 1,
        categoryId: 3,
        isActive: true,
        hasInventory: true, // Tracks inventory
        sellWhenOutOfStock: false, // No backorders
        stockQuantity: 0, // No stock
        typeId: 1, // Regular product
      );
      
      diagnoseProduct(product3);
      expect(product3.isInStock, false, 
        reason: 'This product should be out of stock - all conditions fail');
    });

    test('diagnose common API parsing issues', () {
      // Test different ways the API might send data
      final testCases = [
        // String "0" for has_inventory
        {'has_inventory': '0', 'expected': false, 'description': 'String "0"'},
        // String "1" for has_inventory  
        {'has_inventory': '1', 'expected': true, 'description': 'String "1"'},
        // Boolean false for has_inventory
        {'has_inventory': false, 'expected': false, 'description': 'Boolean false'},
        // Boolean true for has_inventory
        {'has_inventory': true, 'expected': true, 'description': 'Boolean true'},
        // Integer 0 for has_inventory
        {'has_inventory': 0, 'expected': false, 'description': 'Integer 0'},
        // Integer 1 for has_inventory
        {'has_inventory': 1, 'expected': true, 'description': 'Integer 1'},
        // Null/missing has_inventory
        {'has_inventory': null, 'expected': true, 'description': 'Null (should default to true)'},
      ];

      for (final testCase in testCases) {
        final json = {
          'id': 200,
          'title': 'Test Product',
          'vendor_id': 1,
          'category_id': 1,
          'has_inventory': testCase['has_inventory'],
          'variants': [{'id': 1, 'price': '10.00', 'inventory_quantity': 0}],
        };

        final product = ProductModel.fromJson(json);
        
        print('\nTesting has_inventory parsing:');
        print('Input: ${testCase['has_inventory']} (${testCase['description']})');
        print('Parsed hasInventory: ${product.hasInventory}');
        print('Expected: ${testCase['expected']}');
        print('Stock status: ${product.isInStock ? "IN STOCK" : "OUT OF STOCK"}');
        
        expect(product.hasInventory, testCase['expected'],
          reason: 'Failed to parse ${testCase['description']} correctly');
      }
    });

    test('create detailed report for debugging', () {
      // Simulate a batch of products to identify patterns
      final products = [
        ProductModel.fromJson({
          'id': 1,
          'title': 'Always Available (no inventory)',
          'vendor_id': 1,
          'category_id': 1,
          'has_inventory': 0,
          'variants': [{'id': 1, 'price': '10', 'inventory_quantity': 0}],
        }),
        ProductModel.fromJson({
          'id': 2,
          'title': 'In Stock Product',
          'vendor_id': 1,
          'category_id': 1,
          'has_inventory': 1,
          'variants': [{'id': 2, 'price': '15', 'inventory_quantity': 5}],
        }),
        ProductModel.fromJson({
          'id': 3,
          'title': 'Out of Stock Product',
          'vendor_id': 1,
          'category_id': 1,
          'has_inventory': 1,
          'sell_when_out_of_stock': 0,
          'variants': [{'id': 3, 'price': '20', 'inventory_quantity': 0}],
        }),
        ProductModel.fromJson({
          'id': 4,
          'title': 'Service Product',
          'vendor_id': 1,
          'category_id': 1,
          'has_inventory': 1,
          'type_id': 8,
          'variants': [{'id': 4, 'price': '25', 'inventory_quantity': 0}],
        }),
        ProductModel.fromJson({
          'id': 5,
          'title': 'Backorder Product',
          'vendor_id': 1,
          'category_id': 1,
          'has_inventory': 1,
          'sell_when_out_of_stock': 1,
          'variants': [{'id': 5, 'price': '30', 'inventory_quantity': 0}],
        }),
      ];

      print('\n=== PRODUCT AVAILABILITY REPORT ===');
      print('Total Products: ${products.length}');
      
      final inStock = products.where((p) => p.isInStock).toList();
      final outOfStock = products.where((p) => !p.isInStock).toList();
      
      print('In Stock: ${inStock.length}');
      print('Out of Stock: ${outOfStock.length}');
      
      print('\n--- IN STOCK PRODUCTS ---');
      for (final product in inStock) {
        print('✅ ${product.name}');
        if (!product.hasInventory) print('   Reason: Inventory not tracked');
        if (product.productTotalQuantity > 0) print('   Reason: Has stock (${product.productTotalQuantity})');
        if (product.typeId == 8) print('   Reason: Service product');
        if (product.sellWhenOutOfStock) print('   Reason: Allows backorders');
      }
      
      print('\n--- OUT OF STOCK PRODUCTS ---');
      for (final product in outOfStock) {
        print('❌ ${product.name}');
        print('   has_inventory: ${product.hasInventory}');
        print('   stock: ${product.stockQuantity}');
        print('   typeId: ${product.typeId}');
        print('   sell_when_out: ${product.sellWhenOutOfStock}');
      }
      
      print('\n=================================\n');
    });
  });
}