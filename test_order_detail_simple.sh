#!/bin/bash

echo "=== Testing Order Detail API Fix ==="
echo ""

# Step 1: Login
echo "1. Logging in..."
curl -X POST https://yabalash.com/api/v1/auth/login \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "code: 2b5f69" \
  -H "language: 1" \
  -d '{
    "email": "testapp@gmail.com",
    "password": "password",
    "device_type": "iOS",
    "device_token": "test"
  }' 2>/dev/null

echo ""
echo ""
echo "Note: Extract the auth_token from above response"
echo ""

# Example order detail request
echo "2. Example order-detail API request (replace with actual values):"
echo ""
echo "curl -X POST https://yabalash.com/api/v1/order-detail \\"
echo "  -H \"Accept: application/json\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -H \"Authorization: YOUR_AUTH_TOKEN\" \\"
echo "  -H \"code: 2b5f69\" \\"
echo "  -H \"language: 1\" \\"
echo "  -H \"currency: 1\" \\"
echo "  -d '{"
echo "    \"order_id\": 137,"
echo "    \"vendor_id\": 1"
echo "  }'"
echo ""
echo "=== Key Points ==="
echo "1. The 'id' field from orders list is the order_vendor_id"
echo "2. Use 'order_id' field for the actual order ID"
echo "3. Use 'vendor_id' field for the vendor ID"
echo "4. Both order_id and vendor_id are required in the request body"