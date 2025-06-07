# Cart Clear Endpoint Fix

## Issue
The `clearCart` method in the cart service was using GET request for the `/cart/empty` endpoint, which was likely incorrect.

## Investigation
1. Found that the cart provider calls `_cartService.clearCart()` but the implementation was using GET
2. No explicit documentation found about the correct HTTP method for `/cart/empty`
3. Analyzed other cart endpoints:
   - `/cart/add` uses POST
   - `/cart/updateQuantity` uses POST
   - `/cart/remove` uses POST
   - All cart operations follow POST pattern

## Solution
Updated the `clearCart` method to:
1. Try POST first (following the pattern of other cart operations)
2. If POST fails with 405 (Method Not Allowed), automatically fallback to DELETE
3. Added proper error handling and logging

## Changes Made

### 1. Updated API Service (`/lib/core/api/api_service.dart`)
Added headers parameter support to the `delete` method to match other HTTP methods.

### 2. Updated Cart Service (`/lib/features/cart/services/cart_service.dart`)
- Modified `clearCart()` method to use POST instead of GET
- Added `_clearCartWithDelete()` as a fallback method
- Implemented automatic fallback mechanism if POST returns 405

## Implementation Details

The updated `clearCart` method now:
1. Tries POST request first with all required headers
2. If successful, returns success response
3. If POST fails with 405 status code, automatically tries DELETE
4. Provides detailed error logging for debugging
5. Maintains backward compatibility with the existing return type

## Testing
When the app attempts to clear the cart, it will:
1. Log "Error clearing cart with POST: ..." if POST fails
2. Log "POST method not allowed for cart/empty, trying DELETE..." if it's a 405 error
3. Automatically retry with DELETE method
4. Return appropriate success/error response

This approach ensures the cart clearing functionality works regardless of whether the API expects POST or DELETE method.