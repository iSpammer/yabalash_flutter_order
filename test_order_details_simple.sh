#!/bin/bash

# Test order details API to see what data is returned

# Login first
echo "Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "https://yabalash.com/api/v1/login" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "code: 2b5f69" \
  -d '{
    "email": "fasilkk34@gmail.com",
    "password": "11111111",
    "device_type": "android",
    "device_token": "test_token"
  }')

echo "Login response:"
echo "$LOGIN_RESPONSE" | python3 -m json.tool

# Extract token manually
TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import json, sys; print(json.load(sys.stdin)['data']['access_token'])")
echo "Token: $TOKEN"

# Get orders list first to find an active order
echo -e "\nGetting orders list..."
ORDERS_RESPONSE=$(curl -s -X POST "https://yabalash.com/api/v1/orders?type=active" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "code: 2b5f69" \
  -d '{}')

echo -e "\nActive orders response:"
echo "$ORDERS_RESPONSE" | python3 -m json.tool | head -100

# Try a specific order that might have tracking
echo -e "\nGetting order details for a specific order..."

# Try order 137 with vendor 1 (from previous examples)
ORDER_DETAILS=$(curl -s -X POST "https://yabalash.com/api/v1/order-detail" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "code: 2b5f69" \
  -d '{
    "order_id": 137,
    "vendor_id": 1
  }')

echo -e "\nOrder Details Response:"
echo "$ORDER_DETAILS" | python3 -m json.tool | grep -E "(luxury_option_name|dispatcher_status_option_id|dispatch_traking_url|agent_location|driver_id|tasks)" -A 2 -B 2