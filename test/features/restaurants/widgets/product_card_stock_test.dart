import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:yabalash_fe_flutter/features/restaurants/models/product_model.dart';
import 'package:yabalash_fe_flutter/features/restaurants/widgets/product_card.dart';
import 'package:yabalash_fe_flutter/features/cart/providers/cart_provider.dart';
import 'package:go_router/go_router.dart';

void main() {
  // Widget test setup helper
  Widget createTestWidget({
    required ProductModel product,
    CartProvider? cartProvider,
  }) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) => ChangeNotifierProvider(
        create: (_) => cartProvider ?? CartProvider(),
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  body: ProductCard(product: product),
                ),
              ),
              GoRoute(
                path: '/product/:id',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Product Detail')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('ProductCard Stock Display Tests', () {
    testWidgets('should show ADD button when product has_inventory = 0', 
        (WidgetTester tester) async {
      // Arrange - Product with inventory not tracked
      final product = ProductModel(
        id: 1,
        name: 'Always Available Product',
        price: 100.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: false, // has_inventory = 0
        sellWhenOutOfStock: false,
        stockQuantity: 0, // Even with 0 stock
      );

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ADD'), findsOneWidget);
      expect(find.text('OUT OF STOCK'), findsNothing);
    });

    testWidgets('should show ADD button for inactive product with has_inventory = 0', 
        (WidgetTester tester) async {
      // Arrange - Inactive product with inventory not tracked
      final product = ProductModel(
        id: 1,
        name: 'Inactive but Available Product',
        price: 100.0,
        vendorId: 1,
        categoryId: 1,
        isActive: false, // Inactive
        hasInventory: false, // has_inventory = 0
        sellWhenOutOfStock: false,
        stockQuantity: 0,
      );

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert - Should still show ADD because React Native doesn't check isActive
      expect(find.text('ADD'), findsOneWidget);
      expect(find.text('OUT OF STOCK'), findsNothing);
    });

    testWidgets('should show ADD button when product has stock', 
        (WidgetTester tester) async {
      // Arrange
      final product = ProductModel(
        id: 1,
        name: 'In Stock Product',
        price: 100.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: true,
        sellWhenOutOfStock: false,
        stockQuantity: 10, // Has stock
      );

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ADD'), findsOneWidget);
      expect(find.text('OUT OF STOCK'), findsNothing);
    });

    testWidgets('should show ADD button when typeId = 8', 
        (WidgetTester tester) async {
      // Arrange - Special service product
      final product = ProductModel(
        id: 1,
        name: 'Service Product',
        price: 100.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: true,
        sellWhenOutOfStock: false,
        stockQuantity: 0, // No stock
        typeId: 8, // Special type
      );

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ADD'), findsOneWidget);
      expect(find.text('OUT OF STOCK'), findsNothing);
    });

    testWidgets('should show ADD button when sell_when_out_of_stock = true', 
        (WidgetTester tester) async {
      // Arrange
      final product = ProductModel(
        id: 1,
        name: 'Backorder Product',
        price: 100.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: true,
        sellWhenOutOfStock: true, // Allow backorders
        stockQuantity: 0, // No stock
      );

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ADD'), findsOneWidget);
      expect(find.text('OUT OF STOCK'), findsNothing);
    });

    testWidgets('should show OUT OF STOCK only when all conditions fail', 
        (WidgetTester tester) async {
      // Arrange
      final product = ProductModel(
        id: 1,
        name: 'Out of Stock Product',
        price: 100.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: true, // Tracks inventory
        sellWhenOutOfStock: false, // No backorders
        stockQuantity: 0, // No stock
        typeId: 1, // Not special type
      );

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ADD'), findsNothing);
      expect(find.text('OUT OF STOCK'), findsOneWidget);
    });

    testWidgets('should show product name and price correctly', 
        (WidgetTester tester) async {
      // Arrange
      final product = ProductModel(
        id: 1,
        name: 'Test Product Name',
        price: 150.50,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: false,
        sellWhenOutOfStock: false,
        description: 'Test product description',
      );

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Product Name'), findsOneWidget);
      expect(find.text('₹150.50'), findsOneWidget);
      expect(find.text('Test product description'), findsOneWidget);
    });

    testWidgets('should display compare at price with strikethrough', 
        (WidgetTester tester) async {
      // Arrange
      final product = ProductModel(
        id: 1,
        name: 'Discounted Product',
        price: 80.0,
        compareAtPrice: 100.0,
        vendorId: 1,
        categoryId: 1,
        isActive: true,
        hasInventory: false,
        sellWhenOutOfStock: false,
      );

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('₹80.00'), findsOneWidget);
      expect(find.text('₹100.00'), findsOneWidget);
      
      // Check for strikethrough on compare price
      final comparePrice = tester.widget<Text>(find.text('₹100.00'));
      expect(comparePrice.style?.decoration, TextDecoration.lineThrough);
    });
  });
}