#!/bin/bash

# Test script for Yabalash Order Tracking API
# This script tests the order tracking endpoints

# Configuration
API_BASE_URL="https://yabalash.com/api/v1"
AUTH_TOKEN=""  # Will be set after login
CONTENT_TYPE="Content-Type: application/json"
ACCEPT="Accept: application/json"
CODE_HEADER="code: 2b5f69"
LANGUAGE_HEADER="language: 1"

echo "========================================"
echo "Yabalash Order Tracking API Test"
echo "========================================"
echo ""

# 1. Login to get auth token
echo "1. Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/login" \
  -H "$CONTENT_TYPE" \
  -H "$ACCEPT" \
  -H "$CODE_HEADER" \
  -H "$LANGUAGE_HEADER" \
  -d '{
    "email": "testapp@gmail.com",
    "password": "password",
    "device_type": "iOS",
    "device_token": "test-token"
  }')

# Extract auth token
AUTH_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')

if [ -z "$AUTH_TOKEN" ]; then
  echo "❌ Login failed. Response:"
  echo $LOGIN_RESPONSE | jq '.'
  exit 1
fi

echo "✅ Login successful"
echo "   Token: ${AUTH_TOKEN:0:20}..."
echo ""

# 2. Get recent orders
echo "2. Getting recent orders..."
ORDERS=$(curl -s -X GET "$API_BASE_URL/orders?type=active&limit=5" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "$ACCEPT" \
  -H "$CODE_HEADER" \
  -H "$LANGUAGE_HEADER")

echo "Orders response:"
echo $ORDERS | jq '.'
echo ""

# Try to extract first order ID
ORDER_ID=$(echo $ORDERS | jq -r '.data.data[0].id // .data[0].id // empty')

if [ -z "$ORDER_ID" ]; then
  echo "❌ No active orders found. Trying past orders..."
  
  PAST_ORDERS=$(curl -s -X GET "$API_BASE_URL/orders?type=past&limit=5" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -H "$ACCEPT" \
    -H "$CODE_HEADER" \
    -H "$LANGUAGE_HEADER")
  
  ORDER_ID=$(echo $PAST_ORDERS | jq -r '.data.data[0].id // .data[0].id // empty')
fi

if [ -z "$ORDER_ID" ]; then
  echo "❌ No orders found"
  exit 1
fi

echo "✅ Found order ID: $ORDER_ID"
echo ""

# 3. Get order details with tracking
echo "3. Getting order details with tracking info..."
ORDER_DETAILS=$(curl -s -X POST "$API_BASE_URL/order-detail" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "$CONTENT_TYPE" \
  -H "$ACCEPT" \
  -H "$CODE_HEADER" \
  -H "$LANGUAGE_HEADER" \
  -d "{
    \"order_id\": \"$ORDER_ID\"
  }")

echo "Order details response:"
echo $ORDER_DETAILS | jq '.'
echo ""

# Extract tracking information
echo "4. Extracting tracking information..."
echo ""

# Check if response has tracking data
if echo $ORDER_DETAILS | jq -e '.data.order.vendors[0]' > /dev/null 2>&1; then
  VENDOR_DATA=$(echo $ORDER_DETAILS | jq '.data.order.vendors[0]')
  
  echo "📦 Order Tracking Information:"
  echo "================================"
  
  # Extract key tracking fields
  DISPATCH_URL=$(echo $VENDOR_DATA | jq -r '.dispatch_traking_url // "Not available"')
  DISPATCHER_STATUS=$(echo $VENDOR_DATA | jq -r '.dispatcher_status_option_id // "Unknown"')
  ORDER_STATUS=$(echo $VENDOR_DATA | jq -r '.order_status.current_status.title // "Unknown"')
  VENDOR_NAME=$(echo $VENDOR_DATA | jq -r '.vendor_name // "Unknown"')
  
  echo "Vendor: $VENDOR_NAME"
  echo "Order Status: $ORDER_STATUS"
  echo "Dispatcher Status ID: $DISPATCHER_STATUS"
  echo "Tracking URL: $DISPATCH_URL"
  echo ""
  
  # Show dispatcher status stages
  if echo $VENDOR_DATA | jq -e '.vendor_dispatcher_status[0]' > /dev/null 2>&1; then
    echo "Current Status Details:"
    echo $VENDOR_DATA | jq '.vendor_dispatcher_status[0].status_data'
  fi
  
  echo ""
  echo "Available Status Icons:"
  echo $VENDOR_DATA | jq '.dispatcher_status_icons[]' 2>/dev/null || echo "No icons available"
  
else
  echo "❌ No tracking information found in response"
fi

echo ""
echo "========================================"
echo "Test completed"
echo "========================================"