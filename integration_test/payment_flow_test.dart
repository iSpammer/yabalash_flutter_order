import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:yabalash_fe_flutter/main.dart' as app;
import 'package:yabalash_fe_flutter/features/auth/providers/auth_provider.dart';
import 'package:yabalash_fe_flutter/features/cart/providers/cart_provider.dart';
import 'package:yabalash_fe_flutter/features/payment/providers/payment_provider.dart';
import 'package:yabalash_fe_flutter/features/profile/providers/address_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Payment Flow Integration Tests', () {
    testWidgets('Complete payment flow from cart to order success', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login first (if not logged in)
      final loginButton = find.text('Login');
      if (loginButton.evaluate().isNotEmpty) {
        // Fill login form
        await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        
        await tester.tap(loginButton);
        await tester.pumpAndSettle();
      }

      // Navigate to cart
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();

      // Check if cart has items
      final placeOrderButton = find.text('Place Order');
      if (placeOrderButton.evaluate().isEmpty) {
        // Cart is empty, go back and add items
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Add item to cart (assuming we're on a product listing page)
        final addButton = find.text('Add').first;
        if (addButton.evaluate().isNotEmpty) {
          await tester.tap(addButton);
          await tester.pumpAndSettle();
        }

        // Go back to cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();
      }

      // Select address if needed
      final addAddressButton = find.text('Add Delivery Address');
      if (addAddressButton.evaluate().isNotEmpty) {
        await tester.tap(addAddressButton);
        await tester.pumpAndSettle();

        // Fill address form (simplified)
        await tester.enterText(find.byType(TextFormField).first, 'Test Address');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
      }

      // Proceed to payment
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();

      // On payment screen - verify elements
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Payment Method'), findsOneWidget);

      // Select payment method (Cash on Delivery)
      final codPayment = find.text('Cash on Delivery');
      if (codPayment.evaluate().isNotEmpty) {
        await tester.tap(codPayment);
        await tester.pumpAndSettle();
      }

      // Add delivery instructions
      final instructionsField = find.byType(TextFormField).first;
      await tester.enterText(instructionsField, 'Please call before delivery');
      
      // Place order
      await tester.tap(find.text('Place Order').last);
      await tester.pumpAndSettle();

      // Verify order success screen
      expect(find.text('Order Placed Successfully'), findsOneWidget);
    });

    testWidgets('Payment method selection', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to payment screen (assuming user is logged in with items in cart)
      // This is a simplified flow - in real tests you'd set up the proper state

      // Test payment method selection
      final providers = [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
      ];

      await tester.pumpWidget(
        MultiProvider(
          providers: providers,
          child: MaterialApp(
            home: Consumer3<AuthProvider, CartProvider, AddressProvider>(
              builder: (context, auth, cart, address, _) {
                return ChangeNotifierProvider(
                  create: (_) => PaymentProvider(
                    authProvider: auth,
                    cartProvider: cart,
                    addressProvider: address,
                  ),
                  child: const PaymentScreen(),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify payment methods are displayed
      expect(find.text('Payment Method'), findsOneWidget);
      
      // Select different payment methods
      final cardPayment = find.text('Credit Card');
      if (cardPayment.evaluate().isNotEmpty) {
        await tester.tap(cardPayment);
        await tester.pumpAndSettle();
        
        // Verify card input fields appear
        expect(find.text('Card Number'), findsOneWidget);
        expect(find.text('Card Holder Name'), findsOneWidget);
      }
    });

    testWidgets('Card input validation', (WidgetTester tester) async {
      // Create a test widget with card input
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardInputWidget(
              onCardDetailsChanged: (details) {},
            ),
          ),
        ),
      );

      // Enter invalid card number
      await tester.enterText(
        find.byType(TextFormField).first,
        '1234',
      );
      await tester.pump();

      // Enter valid card number
      await tester.enterText(
        find.byType(TextFormField).first,
        '4111111111111111',
      );
      await tester.pump();

      // Verify formatting
      final cardField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(cardField.controller?.text, contains(' ')); // Should have spaces

      // Enter expiry date
      await tester.enterText(
        find.byType(TextFormField).at(2),
        '1225',
      );
      await tester.pump();

      // Verify expiry formatting
      final expiryField = tester.widget<TextFormField>(find.byType(TextFormField).at(2));
      expect(expiryField.controller?.text, '12/25');
    });
  });
}

// Helper imports for the actual screens
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Payment Screen'),
      ),
    );
  }
}

class CardInputWidget extends StatelessWidget {
  final Function(Map<String, String>) onCardDetailsChanged;
  
  const CardInputWidget({
    Key? key,
    required this.onCardDetailsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'Card Number'),
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Card Holder Name'),
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'MM/YY'),
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'CVV'),
        ),
      ],
    );
  }
}