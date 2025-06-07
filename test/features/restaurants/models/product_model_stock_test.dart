import 'package:flutter_test/flutter_test.dart';
import 'package:yabalash_fe_flutter/features/restaurants/models/product_model.dart';
import 'package:yabalash_fe_flutter/features/restaurants/models/variant_model.dart';

void main() {
  group('ProductModel Stock Logic Tests - Match React Native Behavior', () {
    test('should show as in stock when has_inventory is 0 (inventory not tracked)', () {
      // Arrange
      final product = ProductModel(
        id: 1,
        name: 'Test Product',
        price: 10.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: false, // has_inventory = 0
        sellWhenOutOfStock: false,
        stockQuantity: 0, // Even with 0 stock
      );

      // Assert
      expect(product.isInStock, true, 
        reason: 'Product with has_inventory=0 should always be in stock');
    });

    test('should show as in stock when has_inventory is 0 even if inactive', () {
      // Arrange
      final product = ProductModel(
        id: 1,
        name: 'Test Product',
        price: 10.0,
        vendorId: 1,
        categoryId: 1,
        isActive: false, // Inactive product
        hasInventory: false, // has_inventory = 0
        sellWhenOutOfStock: false,
        stockQuantity: 0,
      );

      // Assert - React Native doesn't check isActive for stock
      expect(product.isInStock, true, 
        reason: 'React Native does not check isActive for stock availability');
    });

    test('should show as in stock when productTotalQuantity > 0', () {
      // Arrange
      final product = ProductModel(
        id: 1,
        name: 'Test Product',
        price: 10.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: true,
        sellWhenOutOfStock: false,
        stockQuantity: 5, // Has stock
      );

      // Assert
      expect(product.isInStock, true,
        reason: 'Product with stock > 0 should be in stock');
    });

    test('should show as in stock when typeId is 8', () {
      // Arrange
      final product = ProductModel(
        id: 1,
        name: 'Special Service Product',
        price: 10.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: true,
        sellWhenOutOfStock: false,
        stockQuantity: 0, // No stock
        typeId: 8, // Special type
      );

      // Assert
      expect(product.isInStock, true,
        reason: 'Product with typeId=8 should always be in stock');
    });

    test('should show as in stock when sell_when_out_of_stock is true', () {
      // Arrange
      final product = ProductModel(
        id: 1,
        name: 'Backorder Product',
        price: 10.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: true,
        sellWhenOutOfStock: true, // Allow backorders
        stockQuantity: 0, // No stock
      );

      // Assert
      expect(product.isInStock, true,
        reason: 'Product with sell_when_out_of_stock=true should be in stock');
    });

    test('should show as out of stock only when all conditions fail', () {
      // Arrange
      final product = ProductModel(
        id: 1,
        name: 'Regular Product',
        price: 10.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: true, // has_inventory = 1 (tracks inventory)
        sellWhenOutOfStock: false, // No backorders
        stockQuantity: 0, // No stock
        typeId: 1, // Not special type
      );

      // Assert
      expect(product.isInStock, false,
        reason: 'Product should be out of stock when inventory tracked, no stock, no backorders, not special type');
    });

    test('should handle variant stock when variant is selected', () {
      // Arrange
      final variants = [
        VariantModel(
          id: 1,
          sku: 'VAR1',
          name: 'Small',
          price: 10.0,
          stockQuantity: 5,
        ),
        VariantModel(
          id: 2,
          sku: 'VAR2',
          name: 'Large',
          price: 12.0,
          stockQuantity: 0,
        ),
      ];

      final product = ProductModel(
        id: 1,
        name: 'Variable Product',
        price: 10.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: true,
        sellWhenOutOfStock: false,
        hasVariants: true,
        variants: variants,
      );

      // Test with variant that has stock
      product.selectedVariantId = '1';
      expect(product.isInStock, true,
        reason: 'Should use selected variant stock (5 > 0)');

      // Test with variant that has no stock
      product.selectedVariantId = '2';
      // Note: In React Native, it checks total quantity across all variants,
      // so this would still be true because variant 1 has stock.
      // However, for better UX, we might want to check selected variant specifically
      expect(product.isInStock, true,
        reason: 'React Native checks total quantity (5 from all variants)');
    });

    test('should handle variant with sell_when_out_of_stock', () {
      // Arrange
      final variants = [
        VariantModel(
          id: 1,
          sku: 'VAR1',
          name: 'Small',
          price: 10.0,
          stockQuantity: 0, // No stock
        ),
      ];

      final product = ProductModel(
        id: 1,
        name: 'Variable Product',
        price: 10.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: true,
        sellWhenOutOfStock: true, // Allow backorders
        hasVariants: true,
        variants: variants,
      );

      product.selectedVariantId = '1';
      
      // Assert
      expect(product.isInStock, true,
        reason: 'Variant with 0 stock but sell_when_out_of_stock=true should be in stock');
    });

    test('should show all variants as available when has_inventory is 0', () {
      // Arrange
      final variants = [
        VariantModel(
          id: 1,
          sku: 'VAR1',
          name: 'Small',
          price: 10.0,
          stockQuantity: 0, // No stock
        ),
        VariantModel(
          id: 2,
          sku: 'VAR2',
          name: 'Large',
          price: 12.0,
          stockQuantity: 0, // No stock
        ),
      ];

      final product = ProductModel(
        id: 1,
        name: 'Variable Product',
        price: 10.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: false, // Inventory not tracked
        sellWhenOutOfStock: false,
        hasVariants: true,
        variants: variants,
      );

      // Test both variants
      product.selectedVariantId = '1';
      expect(product.isInStock, true,
        reason: 'Variant should be available when inventory not tracked');

      product.selectedVariantId = '2';
      expect(product.isInStock, true,
        reason: 'All variants should be available when inventory not tracked');
    });

    test('should match React Native exact conditions', () {
      // Test the exact React Native condition:
      // has_inventory == 0 || productTotalQuantity > 0 || typeId == 8 || sell_when_out_of_stock

      // Case 1: Only has_inventory = 0
      var product = ProductModel(
        id: 1, name: 'Test', price: 10.0, vendorId: 1, categoryId: 1,
        isActive: true, hasInventory: false, sellWhenOutOfStock: false,
        stockQuantity: 0, typeId: 1,
      );
      expect(product.isInStock, true);

      // Case 2: Only stock > 0
      product = ProductModel(
        id: 2, name: 'Test', price: 10.0, vendorId: 1, categoryId: 1,
        isActive: true, hasInventory: true, sellWhenOutOfStock: false,
        stockQuantity: 10, typeId: 1,
      );
      expect(product.isInStock, true);

      // Case 3: Only typeId = 8
      product = ProductModel(
        id: 3, name: 'Test', price: 10.0, vendorId: 1, categoryId: 1,
        isActive: true, hasInventory: true, sellWhenOutOfStock: false,
        stockQuantity: 0, typeId: 8,
      );
      expect(product.isInStock, true);

      // Case 4: Only sell_when_out_of_stock = true
      product = ProductModel(
        id: 4, name: 'Test', price: 10.0, vendorId: 1, categoryId: 1,
        isActive: true, hasInventory: true, sellWhenOutOfStock: true,
        stockQuantity: 0, typeId: 1,
      );
      expect(product.isInStock, true);

      // Case 5: All conditions false = out of stock
      product = ProductModel(
        id: 5, name: 'Test', price: 10.0, vendorId: 1, categoryId: 1,
        isActive: true, hasInventory: true, sellWhenOutOfStock: false,
        stockQuantity: 0, typeId: 1,
      );
      expect(product.isInStock, false);
    });
  });
}