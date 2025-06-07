#!/bin/bash

echo "=== Testing Order Detail API Fix ==="
echo ""

# Step 1: Login
echo "1. Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST https://yabalash.com/api/v1/auth/login \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "code: 2b5f69" \
  -H "language: 1" \
  -d '{
    "email": "testapp@gmail.com",
    "password": "password",
    "device_type": "iOS",
    "device_token": "test"
  }')

AUTH_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.auth_token // empty')

if [ -z "$AUTH_TOKEN" ]; then
  echo "Login failed. Response:"
  echo $LOGIN_RESPONSE | jq '.'
  exit 1
fi

echo "Login successful. Token: ${AUTH_TOKEN:0:20}..."
echo ""

# Step 2: Get orders list
echo "2. Getting orders list..."
ORDERS_RESPONSE=$(curl -s -X GET "https://yabalash.com/api/v1/orders?type=active&limit=10" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH_TOKEN" \
  -H "code: 2b5f69" \
  -H "language: 1" \
  -H "currency: 1")

echo "Orders response structure:"
echo $ORDERS_RESPONSE | jq '.data | keys'
echo ""

# Extract first order details
FIRST_ORDER=$(echo $ORDERS_RESPONSE | jq '.data.data[0] // empty')

if [ -z "$FIRST_ORDER" ] || [ "$FIRST_ORDER" = "null" ]; then
  echo "No active orders found. Trying past orders..."
  ORDERS_RESPONSE=$(curl -s -X GET "https://yabalash.com/api/v1/orders?type=past&limit=10" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: $AUTH_TOKEN" \
    -H "code: 2b5f69" \
    -H "language: 1" \
    -H "currency: 1")
  
  FIRST_ORDER=$(echo $ORDERS_RESPONSE | jq '.data.data[0] // empty')
fi

if [ -z "$FIRST_ORDER" ] || [ "$FIRST_ORDER" = "null" ]; then
  echo "No orders found"
  exit 1
fi

echo "First order fields:"
echo $FIRST_ORDER | jq 'keys | sort'
echo ""

# Extract IDs
ORDER_VENDOR_ID=$(echo $FIRST_ORDER | jq -r '.id')
ORDER_ID=$(echo $FIRST_ORDER | jq -r '.order_id')
VENDOR_ID=$(echo $FIRST_ORDER | jq -r '.vendor_id')

echo "=== ID Mapping ==="
echo "order_vendor_id (id field): $ORDER_VENDOR_ID"
echo "order_id: $ORDER_ID"
echo "vendor_id: $VENDOR_ID"
echo ""

# Step 3: Test order detail API with correct parameters
echo "3. Testing order-detail API with correct parameters..."
echo "Request body: {\"order_id\": $ORDER_ID, \"vendor_id\": $VENDOR_ID}"

ORDER_DETAIL_RESPONSE=$(curl -s -X POST https://yabalash.com/api/v1/order-detail \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH_TOKEN" \
  -H "code: 2b5f69" \
  -H "language: 1" \
  -H "currency: 1" \
  -d "{
    \"order_id\": $ORDER_ID,
    \"vendor_id\": $VENDOR_ID
  }")

STATUS_CODE=$(echo $ORDER_DETAIL_RESPONSE | jq -r '.status // empty')

if [ "$STATUS_CODE" = "500" ] || [ "$STATUS_CODE" = "error" ]; then
  echo "Error response:"
  echo $ORDER_DETAIL_RESPONSE | jq '.'
else
  echo "Success! Order detail response structure:"
  echo $ORDER_DETAIL_RESPONSE | jq '.data | keys'
  
  # Check for tracking info
  TRACKING_URL=$(echo $ORDER_DETAIL_RESPONSE | jq -r '.data.vendors[0].dispatch_traking_url // empty')
  DISPATCH_STATUS=$(echo $ORDER_DETAIL_RESPONSE | jq -r '.data.vendors[0].dispatcher_status_option_id // empty')
  
  echo ""
  echo "=== Tracking Information ==="
  echo "Dispatch tracking URL: $TRACKING_URL"
  echo "Dispatcher status: $DISPATCH_STATUS"
fi

echo ""
echo "=== Test Complete ==="