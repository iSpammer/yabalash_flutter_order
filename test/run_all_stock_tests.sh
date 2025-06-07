#!/bin/bash

echo "=== Running Product Stock Tests ==="
echo ""

# First generate mocks
echo "1. Generating mocks..."
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "2. Running unit tests for ProductModel stock logic..."
flutter test test/features/restaurants/models/product_model_stock_test.dart -v

echo ""
echo "3. Running widget tests for ProductCard stock display..."
flutter test test/features/restaurants/widgets/product_card_stock_test.dart -v

echo ""
echo "4. Running API parsing tests..."
flutter test test/features/restaurants/services/product_api_parsing_test.dart -v

echo ""
echo "5. Running diagnostic tests (will show detailed output)..."
flutter test test/features/restaurants/diagnostics/stock_diagnostic_test.dart -v

echo ""
echo "6. Running service mock tests..."
flutter test test/features/restaurants/services/restaurant_service_mock_test.dart -v

echo ""
echo "=== Test Summary ==="
echo "If all tests pass but products still show as inactive in the app,"
echo "the issue is likely in:"
echo "1. API response format differences"
echo "2. Data parsing in the service layer"
echo "3. UI state management"
echo ""
echo "Check the diagnostic output above for clues about specific products."