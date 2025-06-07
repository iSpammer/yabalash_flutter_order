# Yabalash Flutter Test Documentation

## Overview
This document describes the comprehensive test suite created for the Yabalash Flutter application, with a focus on the cart, checkout, payment, and product stock management features.

## Test Structure

### 1. Unit Tests

#### Payment Models (`test/features/payment/models/`)
- **payment_method_model_test.dart**: Tests payment method parsing and type detection
- **place_order_model_test.dart**: Tests order placement response parsing
- Tests cover:
  - JSON parsing from API responses
  - Payment type detection (cash, card, off-site)
  - Order success/failure scenarios

#### Product Stock Logic (`test/features/restaurants/models/`)
- **product_model_stock_test.dart**: Comprehensive tests for product availability logic
- Tests match React Native behavior exactly:
  - `has_inventory = 0` → Always in stock
  - `productTotalQuantity > 0` → In stock
  - `typeId = 8` → Special service, always in stock
  - `sell_when_out_of_stock = true` → Allow backorders
- 10 test cases covering all scenarios

### 2. Widget Tests

#### Product Card (`test/features/restaurants/widgets/`)
- **product_card_stock_test.dart**: Tests UI display of stock status
- Verifies:
  - ADD button shows for available products
  - OUT OF STOCK message for unavailable products
  - Price display and formatting
  - Product information rendering

#### Payment Widgets (`test/features/payment/widgets/`)
- **payment_method_card_test.dart**: Tests payment method selection UI
- **order_summary_widget_test.dart**: Tests order summary display
- **card_input_widget_test.dart**: Tests credit card input validation

### 3. Service Tests

#### Payment Service (`test/features/payment/services/`)
- **payment_service_test.dart**: Tests payment API integration
- Covers:
  - Fetching payment methods
  - Placing orders
  - Error handling
  - Response parsing

#### Restaurant Service (`test/features/restaurants/services/`)
- **restaurant_service_mock_test.dart**: Mock API response tests
- **product_api_parsing_test.dart**: API response parsing tests
- Tests various API response formats:
  - String vs integer values
  - Boolean vs numeric fields
  - Missing fields handling
  - React Native response format compatibility

### 4. Diagnostic Tests

#### Stock Diagnostics (`test/features/restaurants/diagnostics/`)
- **stock_diagnostic_test.dart**: Detailed debugging tests
- Provides:
  - Product stock evaluation reports
  - API parsing diagnostics
  - Comparison with React Native logic
  - Detailed logging for troubleshooting

## Running Tests

### All Tests
```bash
flutter test
```

### Specific Test Categories
```bash
# Unit tests only
flutter test test/features/restaurants/models/
flutter test test/features/payment/models/

# Widget tests only
flutter test test/features/restaurants/widgets/
flutter test test/features/payment/widgets/

# Service tests only
flutter test test/features/payment/services/
flutter test test/features/restaurants/services/

# Diagnostic tests
flutter test test/features/restaurants/diagnostics/
```

### Run Stock Tests Script
```bash
# Make executable
chmod +x test/run_all_stock_tests.sh

# Run all stock-related tests
./test/run_all_stock_tests.sh
```

## Key Test Findings

### Product Stock Issue
The tests revealed that the Flutter implementation correctly matches the React Native logic for product availability. The issue where "products that should be active are being shown as inactive" is likely due to:

1. **API Response Differences**: The API might send different field names or formats
2. **Data Type Mismatches**: String "0" vs integer 0 for `has_inventory`
3. **Missing Fields**: Some products might not have all required fields

### Debugging Tools

#### Stock Debug Logger
Located at `lib/core/utils/stock_debug_logger.dart`, this utility provides:
- Real-time logging of stock evaluations
- API parsing diagnostics
- Comparison with React Native logic
- Product list summaries

Enable in debug mode:
```dart
StockDebugLogger.enable();
```

## Mock Generation

For tests requiring mocks (e.g., provider tests):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Integration Tests

Integration tests are configured but require a running device/emulator:
```bash
flutter test integration_test/
```

## Test Coverage

To generate test coverage reports:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Common Issues and Solutions

### Issue: Products showing as inactive
**Solution**: Check the debug logs for:
- `has_inventory` parsing (should be false for value 0)
- `type_id` values (8 = special service)
- Missing fields in API responses

### Issue: Tests failing due to missing mocks
**Solution**: Run `flutter pub run build_runner build`

### Issue: Widget tests failing
**Solution**: Ensure `flutter_screenutil` is properly initialized in test setup

## Best Practices

1. **Always run tests before committing**
2. **Use diagnostic tests when debugging production issues**
3. **Keep tests synchronized with React Native behavior**
4. **Add new tests when implementing new features**
5. **Use the debug logger in development to track issues**

## Future Improvements

1. Add performance tests for large product lists
2. Create end-to-end tests for complete checkout flow
3. Add golden tests for UI consistency
4. Implement mutation testing for better coverage
5. Add API contract tests