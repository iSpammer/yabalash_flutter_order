import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:yabalash_fe_flutter/features/restaurants/services/restaurant_service.dart';
import 'package:yabalash_fe_flutter/features/restaurants/models/product_model.dart';
import 'package:yabalash_fe_flutter/core/services/api_service.dart';

// This will generate the mock classes
@GenerateMocks([http.Client, ApiService])
import 'restaurant_service_mock_test.mocks.dart';

void main() {
  late RestaurantService restaurantService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    restaurantService = RestaurantService(apiService: mockApiService);
  });

  group('RestaurantService Product Stock Tests', () {
    test('should correctly parse products that should be available despite being marked inactive', () async {
      // Arrange - Mock API response with products that user reports as incorrectly showing unavailable
      final mockResponse = {
        'data': {
          'products': [
            {
              'id': 1001,
              'title': 'Pizza Margherita',
              'vendor_id': 10,
              'category_id': 5,
              'is_live': 0, // Inactive in API
              'has_inventory': 0, // But inventory not tracked
              'sell_when_out_of_stock': 0,
              'variants': [
                {
                  'id': 2001,
                  'price': '15.99',
                  'inventory_quantity': 0,
                }
              ],
            },
            {
              'id': 1002,
              'title': 'Burger Deluxe',
              'vendor_id': 10,
              'category_id': 5,
              'is_live': 1,
              'has_inventory': 0, // Inventory not tracked
              'sell_when_out_of_stock': 0,
              'variants': [
                {
                  'id': 2002,
                  'price': '12.99',
                  'inventory_quantity': 0,
                }
              ],
            },
            {
              'id': 1003,
              'title': 'Pasta Carbonara',
              'vendor_id': 10,
              'category_id': 5,
              'is_live': 1,
              'has_inventory': 1, // Tracks inventory
              'sell_when_out_of_stock': 0,
              'type_id': 8, // Special service type
              'variants': [
                {
                  'id': 2003,
                  'price': '18.50',
                  'inventory_quantity': 0, // No stock but type_id = 8
                }
              ],
            },
          ]
        }
      };

      when(mockApiService.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final products = await restaurantService.getRestaurantProducts(10);

      // Assert
      expect(products.length, 3);
      
      // Product 1: Inactive but has_inventory = 0
      expect(products[0].name, 'Pizza Margherita');
      expect(products[0].isActive, false, reason: 'Product is marked inactive');
      expect(products[0].hasInventory, false, reason: 'Inventory not tracked');
      expect(products[0].isInStock, true, reason: 'Should be in stock because has_inventory = 0');
      
      // Product 2: Active with has_inventory = 0
      expect(products[1].name, 'Burger Deluxe');
      expect(products[1].isActive, true);
      expect(products[1].hasInventory, false);
      expect(products[1].isInStock, true, reason: 'Should be in stock because has_inventory = 0');
      
      // Product 3: Active with type_id = 8
      expect(products[2].name, 'Pasta Carbonara');
      expect(products[2].isActive, true);
      expect(products[2].hasInventory, true);
      expect(products[2].typeId, 8);
      expect(products[2].stockQuantity, 0);
      expect(products[2].isInStock, true, reason: 'Should be in stock because type_id = 8');
    });

    test('should handle React Native API response format', () async {
      // Arrange - Mock response matching React Native format
      final mockResponse = {
        'data': {
          'products': [
            {
              'id': 2001,
              'translation': [
                {
                  'title': 'Special Combo Meal',
                  'body_html': 'Delicious combo with drink',
                }
              ],
              'vendor': {
                'id': 20,
                'name': 'Fast Food Palace',
              },
              'category': {
                'id': 10,
                'category_detail': {
                  'translation': [
                    {'name': 'Combos'}
                  ]
                }
              },
              'variant': [ // Note: React Native uses 'variant' not 'variants'
                {
                  'id': 3001,
                  'price': '25.00',
                  'quantity': 0, // Note: React Native uses 'quantity' not 'inventory_quantity'
                }
              ],
              'has_inventory': 0,
              'is_live': 1,
              'sell_when_out_of_stock': 0,
              'averageRating': '4.2',
              'check_if_in_cart_app': [],
            }
          ]
        }
      };

      when(mockApiService.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final products = await restaurantService.getRestaurantProducts(20);

      // Assert
      expect(products.length, 1);
      expect(products[0].name, 'Special Combo Meal');
      expect(products[0].hasInventory, false);
      expect(products[0].isInStock, true, reason: 'Should be in stock when has_inventory = 0');
      expect(products[0].rating, 4.2);
    });

    test('should identify products that are incorrectly showing as out of stock', () async {
      // Arrange - Products that should be available but might show as unavailable
      final mockResponse = {
        'data': {
          'products': [
            // Case 1: Product with string values
            {
              'id': '3001',
              'title': 'String ID Product',
              'vendor_id': '30',
              'category_id': '5',
              'is_live': '1',
              'has_inventory': '0', // String "0" should parse to false
              'sell_when_out_of_stock': '0',
              'variants': [
                {
                  'id': '4001',
                  'price': '10.00',
                  'inventory_quantity': '0',
                }
              ],
            },
            // Case 2: Product with boolean values
            {
              'id': 3002,
              'title': 'Boolean Values Product',
              'vendor_id': 30,
              'category_id': 5,
              'is_live': true,
              'has_inventory': false, // Boolean false should work
              'sell_when_out_of_stock': false,
              'variants': [
                {
                  'id': 4002,
                  'price': '15.00',
                  'inventory_quantity': 0,
                }
              ],
            },
            // Case 3: Product with missing fields
            {
              'id': 3003,
              'title': 'Minimal Product',
              'vendor_id': 30,
              'category_id': 5,
              // Missing has_inventory, sell_when_out_of_stock, etc.
              'variants': [
                {
                  'id': 4003,
                  'price': '20.00',
                }
              ],
            },
          ]
        }
      };

      when(mockApiService.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final products = await restaurantService.getRestaurantProducts(30);

      // Assert
      expect(products.length, 3);
      
      // String values should parse correctly
      expect(products[0].id, 3001);
      expect(products[0].hasInventory, false);
      expect(products[0].isInStock, true, reason: 'String "0" for has_inventory should make product available');
      
      // Boolean values should parse correctly
      expect(products[1].hasInventory, false);
      expect(products[1].isInStock, true, reason: 'Boolean false for has_inventory should make product available');
      
      // Missing fields should default correctly
      expect(products[2].hasInventory, true, reason: 'Missing has_inventory should default to true');
      expect(products[2].isInStock, false, reason: 'Missing fields with defaults should make product unavailable');
    });

    test('should log when products are marked as out of stock', () async {
      // Arrange - Mix of available and unavailable products
      final mockResponse = {
        'data': {
          'products': [
            {
              'id': 4001,
              'title': 'Available Product',
              'vendor_id': 40,
              'category_id': 5,
              'is_live': 1,
              'has_inventory': 0,
              'variants': [{
                'id': 5001,
                'price': '10.00',
                'inventory_quantity': 0,
              }],
            },
            {
              'id': 4002,
              'title': 'Out of Stock Product',
              'vendor_id': 40,
              'category_id': 5,
              'is_live': 1,
              'has_inventory': 1,
              'sell_when_out_of_stock': 0,
              'type_id': 1,
              'variants': [{
                'id': 5002,
                'price': '15.00',
                'inventory_quantity': 0,
              }],
            },
          ]
        }
      };

      when(mockApiService.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final products = await restaurantService.getRestaurantProducts(40);

      // Assert
      expect(products[0].isInStock, true);
      expect(products[1].isInStock, false);
      
      // Create a diagnostic report
      final availableCount = products.where((p) => p.isInStock).length;
      final unavailableCount = products.where((p) => !p.isInStock).length;
      
      print('Product Stock Report:');
      print('Total products: ${products.length}');
      print('Available: $availableCount');
      print('Unavailable: $unavailableCount');
      
      for (final product in products.where((p) => !p.isInStock)) {
        print('Out of stock: ${product.name} - has_inventory: ${product.hasInventory}, stock: ${product.stockQuantity}, type_id: ${product.typeId}, sell_when_out: ${product.sellWhenOutOfStock}');
      }
    });
  });
}