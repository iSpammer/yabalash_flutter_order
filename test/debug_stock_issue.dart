import 'package:flutter_test/flutter_test.dart';
import 'package:yabalash_fe_flutter/features/restaurants/models/product_model.dart';

/// Quick test to debug specific products that users report as showing incorrectly
/// Run with: flutter test test/debug_stock_issue.dart
void main() {
  group('Debug Specific Stock Issues', () {
    test('debug products that user reports as inactive but should be active', () {
      // Example 1: Product with has_inventory = "0" (string zero)
      print('\n=== CASE 1: String "0" for has_inventory ===');
      final case1 = {
        'id': 101,
        'title': 'Pizza that should be available',
        'vendor_id': 1,
        'category_id': 5,
        'is_live': 1,
        'has_inventory': '0', // String "0" - should parse as inventory not tracked
        'sell_when_out_of_stock': 0,
        'variants': [
          {'id': 201, 'price': '15.99', 'inventory_quantity': 0}
        ],
      };
      
      final product1 = ProductModel.fromJson(case1);
      print('Product: ${product1.name}');
      print('Raw has_inventory: "${case1['has_inventory']}" (${case1['has_inventory'].runtimeType})');
      print('Parsed hasInventory: ${product1.hasInventory}');
      print('Stock quantity: ${product1.stockQuantity}');
      print('Is in stock: ${product1.isInStock}');
      print('Expected: true (because has_inventory should be false)');
      
      // Example 2: Inactive product with has_inventory = 0
      print('\n=== CASE 2: Inactive product with has_inventory = 0 ===');
      final case2 = {
        'id': 102,
        'title': 'Inactive Pizza but should still show ADD button',
        'vendor_id': 1,
        'category_id': 5,
        'is_live': 0, // Inactive
        'has_inventory': 0, // Integer 0
        'sell_when_out_of_stock': 0,
        'variants': [
          {'id': 202, 'price': '12.99', 'inventory_quantity': 0}
        ],
      };
      
      final product2 = ProductModel.fromJson(case2);
      print('Product: ${product2.name}');
      print('Is active: ${product2.isActive}');
      print('Has inventory: ${product2.hasInventory}');
      print('Is in stock: ${product2.isInStock}');
      print('Expected: true (React Native doesn\'t check isActive)');
      
      // Example 3: Service product (type_id = 8)
      print('\n=== CASE 3: Service product with no stock ===');
      final case3 = {
        'id': 103,
        'title': 'Delivery Service',
        'vendor_id': 1,
        'category_id': 8,
        'is_live': 1,
        'has_inventory': 1,
        'sell_when_out_of_stock': 0,
        'type_id': 8, // Service type
        'variants': [
          {'id': 203, 'price': '5.00', 'inventory_quantity': 0}
        ],
      };
      
      final product3 = ProductModel.fromJson(case3);
      print('Product: ${product3.name}');
      print('Type ID: ${product3.typeId}');
      print('Stock: ${product3.stockQuantity}');
      print('Is in stock: ${product3.isInStock}');
      print('Expected: true (service products always available)');
      
      // Example 4: React Native format
      print('\n=== CASE 4: React Native API format ===');
      final case4 = {
        'id': 104,
        'translation': [
          {'title': 'React Native Format Product'}
        ],
        'vendor': {'id': 1, 'name': 'Test Vendor'},
        'variant': [ // Note: 'variant' not 'variants'
          {'id': 204, 'price': '20.00', 'quantity': 0} // Note: 'quantity' not 'inventory_quantity'
        ],
        'has_inventory': 0,
        'is_live': 1,
      };
      
      final product4 = ProductModel.fromJson(case4);
      print('Product: ${product4.name}');
      print('Has inventory: ${product4.hasInventory}');
      print('Is in stock: ${product4.isInStock}');
      print('Expected: true');
      
      // Summary
      print('\n=== SUMMARY ===');
      final products = [product1, product2, product3, product4];
      final inStock = products.where((p) => p.isInStock).length;
      final outOfStock = products.where((p) => !p.isInStock).length;
      
      print('Total tested: ${products.length}');
      print('In stock: $inStock');
      print('Out of stock: $outOfStock');
      
      if (outOfStock > 0) {
        print('\nProducts showing as OUT OF STOCK:');
        for (final p in products.where((p) => !p.isInStock)) {
          print('- ${p.name}');
        }
      }
      
      // Assertions
      expect(product1.isInStock, true, reason: 'String "0" for has_inventory should make product available');
      expect(product2.isInStock, true, reason: 'Inactive products with has_inventory=0 should be available');
      expect(product3.isInStock, true, reason: 'Service products should always be available');
      expect(product4.isInStock, true, reason: 'React Native format should parse correctly');
    });
    
    test('test actual problematic product data', () {
      // TODO: Replace with actual product data from API that's showing incorrectly
      // Example format:
      final problematicProduct = {
        'id': 999,
        'title': 'Actual Product Name Here',
        'vendor_id': 123,
        'category_id': 456,
        'is_live': 1,
        'has_inventory': '0', // Or whatever the actual value is
        'sell_when_out_of_stock': 0,
        'type_id': null,
        'variants': [
          {
            'id': 789,
            'price': '25.00',
            'inventory_quantity': 0,
          }
        ],
      };
      
      print('\n=== TESTING ACTUAL PROBLEMATIC PRODUCT ===');
      final product = ProductModel.fromJson(problematicProduct);
      
      print('Product ID: ${product.id}');
      print('Name: ${product.name}');
      print('Active: ${product.isActive}');
      print('Has Inventory: ${product.hasInventory}');
      print('Stock: ${product.stockQuantity}');
      print('Type ID: ${product.typeId}');
      print('Sell When Out: ${product.sellWhenOutOfStock}');
      print('Result: ${product.isInStock ? "IN STOCK" : "OUT OF STOCK"}');
      
      // Add expectation based on what it should be
      // expect(product.isInStock, true, reason: 'This product should be available');
    });
  });
}