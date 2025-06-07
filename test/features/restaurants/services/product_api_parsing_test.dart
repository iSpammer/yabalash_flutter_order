import 'package:flutter_test/flutter_test.dart';
import 'package:yabalash_fe_flutter/features/restaurants/models/product_model.dart';

void main() {
  group('Product API Response Parsing Tests', () {
    test('should correctly parse product with has_inventory = 0', () {
      // Arrange - Mock API response for product that should be available
      final apiResponse = {
        'id': 123,
        'sku': 'PROD123',
        'title': 'Always Available Product',
        'body_html': 'This product is always available',
        'vendor': 'Test Vendor',
        'product_type': 'Food',
        'tags': [],
        'variants': [
          {
            'id': 456,
            'product_id': 123,
            'title': 'Default',
            'price': '15.00',
            'sku': 'PROD123-DEFAULT',
            'inventory_quantity': 0,
          }
        ],
        'images': [
          {
            'id': 789,
            'product_id': 123,
            'src': 'https://example.com/image.jpg',
          }
        ],
        'vendor_id': 1,
        'category_id': 5,
        'is_live': 1,
        'has_inventory': 0, // Key field - inventory not tracked
        'sell_when_out_of_stock': 0,
        'requires_shipping': 1,
        'Requires_last_mile': 1,
        'averageRating': 4.5,
      };

      // Act
      final product = ProductModel.fromJson(apiResponse);

      // Assert
      expect(product.hasInventory, false, reason: 'has_inventory should be false when API returns 0');
      expect(product.isInStock, true, reason: 'Product should be in stock when has_inventory = 0');
      expect(product.stockQuantity, 0, reason: 'Stock quantity can be 0 when inventory not tracked');
    });

    test('should correctly parse product with type_id = 8', () {
      // Arrange - Mock API response for special service product
      final apiResponse = {
        'id': 124,
        'sku': 'SERVICE001',
        'title': 'Special Service Product',
        'vendor': 'Service Vendor',
        'product_type': 'Service',
        'variants': [
          {
            'id': 457,
            'product_id': 124,
            'title': 'Service',
            'price': '50.00',
            'inventory_quantity': 0,
          }
        ],
        'vendor_id': 2,
        'category_id': 8,
        'is_live': 1,
        'has_inventory': 1,
        'sell_when_out_of_stock': 0,
        'type_id': 8, // Special service type
        'averageRating': 0,
      };

      // Act
      final product = ProductModel.fromJson(apiResponse);

      // Assert
      expect(product.typeId, 8, reason: 'type_id should be parsed correctly');
      expect(product.hasInventory, true, reason: 'has_inventory should be true when API returns 1');
      expect(product.stockQuantity, 0, reason: 'Stock is 0');
      expect(product.isInStock, true, reason: 'Product should be in stock when type_id = 8');
    });

    test('should correctly parse product with sell_when_out_of_stock = 1', () {
      // Arrange - Mock API response for backorder product
      final apiResponse = {
        'id': 125,
        'title': 'Backorder Product',
        'vendor': 'Backorder Vendor',
        'variants': [
          {
            'id': 458,
            'product_id': 125,
            'title': 'Default',
            'price': '25.00',
            'inventory_quantity': 0,
          }
        ],
        'vendor_id': 3,
        'category_id': 2,
        'is_live': 1,
        'has_inventory': 1,
        'sell_when_out_of_stock': 1, // Allow backorders
        'averageRating': 3.0,
      };

      // Act
      final product = ProductModel.fromJson(apiResponse);

      // Assert
      expect(product.sellWhenOutOfStock, true, reason: 'sell_when_out_of_stock should be true when API returns 1');
      expect(product.stockQuantity, 0, reason: 'Stock is 0');
      expect(product.isInStock, true, reason: 'Product should be in stock when sell_when_out_of_stock = 1');
    });

    test('should correctly parse inactive product that should still be available', () {
      // Arrange - Inactive product with has_inventory = 0
      final apiResponse = {
        'id': 126,
        'title': 'Inactive but Available Product',
        'vendor': 'Test Vendor',
        'variants': [
          {
            'id': 459,
            'product_id': 126,
            'title': 'Default',
            'price': '30.00',
            'inventory_quantity': 0,
          }
        ],
        'vendor_id': 1,
        'category_id': 3,
        'is_live': 0, // Inactive
        'has_inventory': 0, // But inventory not tracked
        'sell_when_out_of_stock': 0,
      };

      // Act
      final product = ProductModel.fromJson(apiResponse);

      // Assert
      expect(product.isActive, false, reason: 'is_live = 0 should parse to isActive = false');
      expect(product.hasInventory, false, reason: 'has_inventory = 0 should parse to hasInventory = false');
      expect(product.isInStock, true, reason: 'Inactive product should still show as in stock when has_inventory = 0');
    });

    test('should correctly parse product with inventory and stock', () {
      // Arrange - Regular product with stock
      final apiResponse = {
        'id': 127,
        'title': 'In Stock Product',
        'vendor': 'Stock Vendor',
        'variants': [
          {
            'id': 460,
            'product_id': 127,
            'title': 'Default',
            'price': '20.00',
            'inventory_quantity': 15,
          }
        ],
        'vendor_id': 4,
        'category_id': 1,
        'is_live': 1,
        'has_inventory': 1,
        'sell_when_out_of_stock': 0,
      };

      // Act
      final product = ProductModel.fromJson(apiResponse);

      // Assert
      expect(product.isActive, true);
      expect(product.hasInventory, true);
      expect(product.stockQuantity, 15);
      expect(product.isInStock, true, reason: 'Product with stock > 0 should be in stock');
    });

    test('should correctly parse out of stock product', () {
      // Arrange - Product that should be out of stock
      final apiResponse = {
        'id': 128,
        'title': 'Out of Stock Product',
        'vendor': 'No Stock Vendor',
        'variants': [
          {
            'id': 461,
            'product_id': 128,
            'title': 'Default',
            'price': '35.00',
            'inventory_quantity': 0,
          }
        ],
        'vendor_id': 5,
        'category_id': 4,
        'is_live': 1,
        'has_inventory': 1, // Tracks inventory
        'sell_when_out_of_stock': 0, // No backorders
        'type_id': 1, // Regular type
      };

      // Act
      final product = ProductModel.fromJson(apiResponse);

      // Assert
      expect(product.isActive, true);
      expect(product.hasInventory, true);
      expect(product.sellWhenOutOfStock, false);
      expect(product.stockQuantity, 0);
      expect(product.typeId, 1);
      expect(product.isInStock, false, reason: 'Product should be out of stock when all conditions fail');
    });

    test('should handle missing or null fields gracefully', () {
      // Arrange - Minimal API response
      final apiResponse = {
        'id': 129,
        'title': 'Minimal Product',
        'vendor_id': 1,
        'category_id': 1,
        // Missing many fields
      };

      // Act
      final product = ProductModel.fromJson(apiResponse);

      // Assert
      expect(product.isActive, true, reason: 'Default should be active');
      expect(product.hasInventory, true, reason: 'Default should track inventory');
      expect(product.sellWhenOutOfStock, false, reason: 'Default should not allow backorders');
      expect(product.stockQuantity, 0, reason: 'Default stock should be 0');
      expect(product.typeId, null, reason: 'Missing type_id should be null');
      expect(product.isInStock, false, reason: 'Default product with no special conditions should be out of stock');
    });

    test('should correctly calculate productTotalQuantity from variants', () {
      // Arrange - Product with multiple variants
      final apiResponse = {
        'id': 130,
        'title': 'Multi-variant Product',
        'vendor_id': 1,
        'category_id': 1,
        'has_inventory': 1,
        'sell_when_out_of_stock': 0,
        'variants': [
          {
            'id': 462,
            'product_id': 130,
            'title': 'Small',
            'price': '10.00',
            'inventory_quantity': 5,
          },
          {
            'id': 463,
            'product_id': 130,
            'title': 'Medium',
            'price': '12.00',
            'inventory_quantity': 3,
          },
          {
            'id': 464,
            'product_id': 130,
            'title': 'Large',
            'price': '15.00',
            'inventory_quantity': 0,
          }
        ],
      };

      // Act
      final product = ProductModel.fromJson(apiResponse);

      // Assert
      expect(product.hasVariants, true);
      expect(product.variants?.length, 3);
      expect(product.productTotalQuantity, 8, reason: 'Total quantity should be sum of all variants (5+3+0)');
      expect(product.isInStock, true, reason: 'Product should be in stock when total quantity > 0');
    });

    test('should parse complex React Native response format', () {
      // Arrange - Actual React Native API response format from ProductsCompTwo.js
      final apiResponse = {
        'id': 131,
        'translation': [
          {
            'title': 'Product Name in English',
            'body_html': 'Product description',
          }
        ],
        'category': {
          'category_detail': {
            'translation': [
              {'name': 'Food Category'}
            ]
          }
        },
        'media': [
          {
            'image': {
              'path': {
                'image_fit': '600/600',
                'image_path': 'products/image.jpg',
              }
            }
          }
        ],
        'vendor': {
          'id': 1,
          'name': 'Vendor Name',
        },
        'variant': [
          {
            'id': 465,
            'price': '25.50',
            'quantity': 10,
          }
        ],
        'has_inventory': 0,
        'type_id': 1,
        'sell_when_out_of_stock': 0,
        'is_live': 1,
        'check_if_in_cart_app': [],
        'add_on_count': 2,
        'variant_set_count': 1,
        'averageRating': '4.5',
      };

      // Act
      final product = ProductModel.fromJson(apiResponse);

      // Assert
      expect(product.hasInventory, false, reason: 'has_inventory = 0');
      expect(product.isInStock, true, reason: 'Should be in stock when has_inventory = 0');
      expect(product.rating, 4.5);
      // Note: Some fields might not parse correctly if Flutter model expects different structure
    });
  });

  group('Edge Case Tests', () {
    test('should handle string values for numeric fields', () {
      // Arrange - API might return strings for numbers
      final apiResponse = {
        'id': '132', // String instead of int
        'title': 'String Number Product',
        'vendor_id': '1',
        'category_id': '2',
        'has_inventory': '0', // String instead of int
        'sell_when_out_of_stock': '1',
        'type_id': '8',
        'variants': [
          {
            'id': '466',
            'price': '19.99',
            'inventory_quantity': '5', // String instead of int
          }
        ],
      };

      // Act
      final product = ProductModel.fromJson(apiResponse);

      // Assert
      expect(product.id, 132);
      expect(product.vendorId, 1);
      expect(product.hasInventory, false);
      expect(product.sellWhenOutOfStock, true);
      expect(product.typeId, 8);
      expect(product.stockQuantity, 5);
      expect(product.isInStock, true);
    });

    test('should handle boolean values for numeric fields', () {
      // Arrange - API might return booleans
      final apiResponse = {
        'id': 133,
        'title': 'Boolean Values Product',
        'vendor_id': 1,
        'category_id': 1,
        'has_inventory': false, // Boolean instead of int
        'sell_when_out_of_stock': true, // Boolean instead of int
        'is_live': true, // Boolean instead of int
      };

      // Act
      final product = ProductModel.fromJson(apiResponse);

      // Assert
      expect(product.hasInventory, false);
      expect(product.sellWhenOutOfStock, true);
      expect(product.isActive, true);
      expect(product.isInStock, true, reason: 'Should be in stock when has_inventory is false');
    });
  });
}