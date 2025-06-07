# Testing Guide for Yabalash Flutter Payment System

## Overview
This guide covers the comprehensive testing strategy for the payment flow implementation in the Yabalash Flutter app.

## Test Structure

### 1. Unit Tests
Located in `test/features/payment/`

#### Model Tests (`models/`)
- **payment_method_model_test.dart**: Tests PaymentMethod model parsing and logic
  - JSON parsing
  - Payment type identification (cash, card, off-site)
  - Active status checking

- **place_order_model_test.dart**: Tests order placement models
  - Request JSON generation
  - Response parsing for different scenarios
  - Error handling

#### Service Tests (`services/`)
- **payment_service_test.dart**: Tests payment service logic
  - API request formatting
  - Response handling
  - Error scenarios

### 2. Widget Tests
Located in `test/features/payment/widgets/`

- **payment_method_card_test.dart**: Tests payment method selection UI
  - Visual rendering
  - User interaction
  - State changes
  - Icon display logic

### 3. Provider Tests
Located in `test/features/payment/providers/`

- **payment_provider_test.dart**: Tests state management
  - Payment method selection
  - Form data management
  - Validation logic
  - Error handling

### 4. Integration Tests
Located in `integration_test/`

- **payment_flow_test.dart**: End-to-end payment flow testing
  - Complete checkout process
  - Payment method selection
  - Order placement
  - Success/failure scenarios

## Running Tests

### Quick Run
```bash
# Run all tests
./run_tests.sh

# Run specific test file
flutter test test/features/payment/models/payment_method_model_test.dart

# Run all tests with coverage
flutter test --coverage

# Run integration tests (requires device/emulator)
flutter test integration_test/payment_flow_test.dart
```

### Test Categories

#### Unit Tests Only
```bash
flutter test test/features/payment/models/
flutter test test/features/payment/services/
```

#### Widget Tests Only
```bash
flutter test test/features/payment/widgets/
```

#### Integration Tests
```bash
# Start emulator/connect device first
flutter test integration_test/
```

## Test Coverage Areas

### ✅ Covered
1. **Payment Method Model**
   - JSON parsing
   - Type identification
   - Status checking

2. **Place Order Model**
   - Request generation
   - Response parsing
   - Different payment scenarios

3. **Payment Method Card Widget**
   - UI rendering
   - Selection state
   - Icon display
   - User interaction

4. **Payment Service Logic**
   - Request formatting
   - Response handling

### 🔄 Partial Coverage
1. **Payment Provider**
   - Basic state management
   - Validation logic
   - (Requires mock setup for full coverage)

2. **Integration Flow**
   - Basic flow structure
   - (Requires running app for full testing)

### 📋 TODO
1. **Mock Setup**
   - Run `flutter pub run build_runner build` to generate mocks
   - Complete provider tests with mocks

2. **API Integration Tests**
   - Mock API responses
   - Test error scenarios
   - Network failure handling

3. **WebView Tests**
   - Payment gateway navigation
   - Success/failure detection
   - Callback handling

## Writing New Tests

### Unit Test Template
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yabalash_fe_flutter/features/payment/...';

void main() {
  group('Feature Tests', () {
    test('should do something', () {
      // Arrange
      final input = ...;
      
      // Act
      final result = ...;
      
      // Assert
      expect(result, expectedValue);
    });
  });
}
```

### Widget Test Template
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should render correctly', (WidgetTester tester) async {
    // Arrange & Act
    await tester.pumpWidget(
      MaterialApp(
        home: YourWidget(),
      ),
    );
    
    // Assert
    expect(find.text('Expected Text'), findsOneWidget);
  });
}
```

## Best Practices

1. **Test Naming**: Use descriptive names that explain what is being tested
2. **AAA Pattern**: Arrange, Act, Assert for clear test structure
3. **Isolation**: Each test should be independent
4. **Coverage**: Aim for >80% code coverage
5. **Edge Cases**: Test boundary conditions and error scenarios

## Continuous Integration

Add to your CI/CD pipeline:
```yaml
test:
  stage: test
  script:
    - flutter test --coverage
    - genhtml coverage/lcov.info -o coverage/html
  artifacts:
    paths:
      - coverage/
```

## Debugging Tests

```bash
# Run tests with verbose output
flutter test --verbose

# Run specific test by name
flutter test --name "should create PaymentMethod from JSON"

# Debug mode
flutter test --dart-define=DEBUG=true
```