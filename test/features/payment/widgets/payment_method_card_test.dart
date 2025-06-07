import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yabalash_fe_flutter/features/payment/models/payment_method_model.dart';
import 'package:yabalash_fe_flutter/features/payment/widgets/payment_method_card.dart';

void main() {
  // Widget test setup helper
  Widget createTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('PaymentMethodCard Widget Tests', () {
    testWidgets('should display payment method title', (WidgetTester tester) async {
      // Arrange
      final paymentMethod = PaymentMethod(
        id: 1,
        title: 'Credit Card',
        status: 1,
      );
      bool tapped = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          PaymentMethodCard(
            paymentMethod: paymentMethod,
            isSelected: false,
            onTap: () => tapped = true,
          ),
        ),
      );

      // Assert
      expect(find.text('Credit Card'), findsOneWidget);
    });

    testWidgets('should show selected state', (WidgetTester tester) async {
      // Arrange
      final paymentMethod = PaymentMethod(
        id: 1,
        title: 'Credit Card',
        status: 1,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          PaymentMethodCard(
            paymentMethod: paymentMethod,
            isSelected: true,
            onTap: () {},
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(PaymentMethodCard),
          matching: find.byType(Container).first,
        ),
      );
      
      // Check if container has selected styling
      expect(container.decoration, isNotNull);
    });

    testWidgets('should show correct icon for cash payment', (WidgetTester tester) async {
      // Arrange
      final paymentMethod = PaymentMethod(
        id: 1,
        title: 'Cash on Delivery',
        code: 'cod',
        status: 1,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          PaymentMethodCard(
            paymentMethod: paymentMethod,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.money), findsOneWidget);
    });

    testWidgets('should show correct icon for card payment', (WidgetTester tester) async {
      // Arrange
      final paymentMethod = PaymentMethod(
        id: 1,
        title: 'Credit Card',
        code: 'stripe',
        status: 1,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          PaymentMethodCard(
            paymentMethod: paymentMethod,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.credit_card), findsOneWidget);
    });

    testWidgets('should show off-site payment indicator', (WidgetTester tester) async {
      // Arrange
      final paymentMethod = PaymentMethod(
        id: 1,
        title: 'PayPal',
        offSite: 1,
        status: 1,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          PaymentMethodCard(
            paymentMethod: paymentMethod,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );

      // Assert
      expect(find.text('Redirects to payment gateway'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      // Arrange
      final paymentMethod = PaymentMethod(
        id: 1,
        title: 'Credit Card',
        status: 1,
      );
      bool tapped = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          PaymentMethodCard(
            paymentMethod: paymentMethod,
            isSelected: false,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Assert
      expect(tapped, true);
    });

    testWidgets('should display radio button with correct state', (WidgetTester tester) async {
      // Arrange
      final paymentMethod = PaymentMethod(
        id: 1,
        title: 'Credit Card',
        status: 1,
      );

      // Act - Test selected state
      await tester.pumpWidget(
        createTestWidget(
          PaymentMethodCard(
            paymentMethod: paymentMethod,
            isSelected: true,
            onTap: () {},
          ),
        ),
      );

      // Assert
      final radio = tester.widget<Radio<int>>(find.byType(Radio<int>));
      expect(radio.value, 1);
      expect(radio.groupValue, 1);

      // Act - Test unselected state
      await tester.pumpWidget(
        createTestWidget(
          PaymentMethodCard(
            paymentMethod: paymentMethod,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      // Assert
      final unselectedRadio = tester.widget<Radio<int>>(find.byType(Radio<int>));
      expect(unselectedRadio.groupValue, null);
    });
  });
}