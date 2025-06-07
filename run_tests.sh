#!/bin/bash

echo "Running Flutter Payment Flow Tests"
echo "================================="

# Run unit tests
echo -e "\n📋 Running Unit Tests..."
flutter test test/features/payment/models/
flutter test test/features/payment/services/

# Run widget tests
echo -e "\n🎨 Running Widget Tests..."
flutter test test/features/payment/widgets/

# Run provider tests (if mocks are set up)
# echo -e "\n🔧 Running Provider Tests..."
# flutter test test/features/payment/providers/

# Run integration tests (requires device/emulator)
# echo -e "\n🚀 Running Integration Tests..."
# flutter test integration_test/

echo -e "\n✅ All tests completed!"
echo "================================="

# Generate coverage report (optional)
# echo -e "\n📊 Generating Coverage Report..."
# flutter test --coverage
# genhtml coverage/lcov.info -o coverage/html
# echo "Coverage report generated at coverage/html/index.html"