#!/bin/bash

# Test Authentication Flow Script
# This script tests the authentication endpoints based on the provided API guide

API_URL="https://yabalash.com/api/v1"
HEADERS="-H 'Accept: application/json' -H 'Content-Type: application/json' -H 'code: 2b5f69' -H 'language: 1'"

echo "=== Testing Yabalash Authentication Flow ==="
echo

# Test 1: Register with Email
echo "1. Testing User Registration..."
echo "   POST $API_URL/auth/register"
curl --http1.1 -X POST "$API_URL/auth/register" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "code: 2b5f69" \
  -H "language: 1" \
  -d '{
    "name": "Test User",
    "email": "test'$(date +%s)'@example.com",
    "phone_number": "50'$(date +%s | tail -c 8)'",
    "dial_code": "971",
    "password": "TestPass123",
    "country_code": "AE",
    "device_type": "android",
    "device_token": "test_fcm_token_'$(date +%s)'"
  }' | jq '.'

echo
echo "---"
echo

# Test 2: Login with Email
echo "2. Testing User Login..."
echo "   POST $API_URL/auth/login"
curl --http1.1 -X POST "$API_URL/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "code: 2b5f69" \
  -H "language: 1" \
  -d '{
    "email": "john.doe@example.com",
    "password": "SecurePass123",
    "device_type": "android",
    "device_token": "test_fcm_token_'$(date +%s)'"
  }' | jq '.'

echo
echo "---"
echo

# Test 3: Get Social Login Info
echo "3. Testing Social Login Info..."
echo "   POST $API_URL/social/info"
curl --http1.1 -X POST "$API_URL/social/info" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "code: 2b5f69" \
  -d '{
    "type": "google"
  }' | jq '.'

echo
echo "---"
echo

# Test 4: Test Password Validation (weak password)
echo "4. Testing Password Validation (weak password)..."
echo "   POST $API_URL/auth/register"
curl --http1.1 -X POST "$API_URL/auth/register" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "code: 2b5f69" \
  -H "language: 1" \
  -d '{
    "name": "Test User",
    "email": "weakpass'$(date +%s)'@example.com",
    "phone_number": "50'$(date +%s | tail -c 8)'",
    "dial_code": "971",
    "password": "weak",
    "country_code": "AE",
    "device_type": "android",
    "device_token": "test_fcm_token"
  }' | jq '.'

echo
echo "=== Test Complete ==="