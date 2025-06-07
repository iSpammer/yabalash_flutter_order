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

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.access_token')
echo "Token: $TOKEN"

# Get orders list first to find an active order
echo -e "\nGetting orders list..."
ORDERS_RESPONSE=$(curl -s -X POST "https://yabalash.com/api/v1/orders?type=active" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "code: 2b5f69" \
  -d '{}')

echo -e "\nActive orders:"
echo $ORDERS_RESPONSE | jq '.data.data[] | {id: .id, order_id: .order_id, vendor_id: .vendor_id, status: .order_status, dispatcher_status: .dispatcher_status_option_id, dispatch_url: .dispatch_traking_url, luxury_option: .luxury_option_name}'

# Get the first active order's details
FIRST_ORDER=$(echo $ORDERS_RESPONSE | jq -r '.data.data[0]')
if [ "$FIRST_ORDER" != "null" ]; then
  ORDER_ID=$(echo $FIRST_ORDER | jq -r '.order_id')
  VENDOR_ID=$(echo $FIRST_ORDER | jq -r '.vendor_id')
  
  echo -e "\nGetting order details for order_id: $ORDER_ID, vendor_id: $VENDOR_ID"
  
  ORDER_DETAILS=$(curl -s -X POST "https://yabalash.com/api/v1/order-detail" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "code: 2b5f69" \
    -d "{
      \"order_id\": $ORDER_ID,
      \"vendor_id\": $VENDOR_ID
    }")
  
  echo -e "\nOrder Details Response:"
  echo $ORDER_DETAILS | jq '.'
  
  # Check specific fields
  echo -e "\nKey tracking fields:"
  echo $ORDER_DETAILS | jq '.data | {
    luxury_option_name: .luxury_option_name,
    order_status: .order_status,
    agent_location: .agent_location,
    tasks: .tasks,
    vendors: .vendors[] | {
      id: .id,
      dispatcher_status_option_id: .dispatcher_status_option_id,
      dispatch_traking_url: .dispatch_traking_url,
      driver_id: .driver_id,
      vendor_dispatcher_status: .vendor_dispatcher_status,
      agent_location: .agent_location,
      tasks: .tasks
    }
  }'
fi