# Tracking URL Navigation Fix

## Problem
When navigating to order details with a tracking URL, the app was getting a routing error because the URL contains forward slashes that were being interpreted as route segments.

## Solution

### 1. URL Encoding in Navigation
In `orders_screen.dart`, the navigation now properly encodes the tracking URL:

```dart
void _navigateToOrderDetails(OrderModel order) {
  // Get tracking URL from vendor if available
  String? trackingUrl;
  if (order.vendors != null && order.vendors!.isNotEmpty) {
    trackingUrl = order.vendors!.first.dispatchTrakingUrl;
  }
  
  // Use Uri encoding for the tracking URL to handle special characters
  final encodedTrackingUrl = trackingUrl != null && trackingUrl.isNotEmpty
      ? Uri.encodeComponent(trackingUrl)
      : 'none';
  
  context.push('/order/details/${order.id}/$encodedTrackingUrl');
}
```

### 2. URL Decoding in Order Details
In `order_details_screen.dart`, the tracking URL is decoded and used:

```dart
@override
void initState() {
  super.initState();
  
  // Decode the tracking URL if provided
  if (widget.trackingId != 'none' && widget.trackingId.isNotEmpty) {
    try {
      _currentTrackingUrl = Uri.decodeComponent(widget.trackingId);
      debugPrint('Decoded tracking URL: $_currentTrackingUrl');
      
      // Validate it's a dispatch URL
      if (_currentTrackingUrl != null && 
          _currentTrackingUrl!.contains('dispatch.yabalash.com/order/tracking/')) {
        debugPrint('✅ Valid dispatch tracking URL provided');
      }
    } catch (e) {
      debugPrint('Error decoding tracking URL: $e');
    }
  }
  
  // ... rest of initialization
  
  // If we have a tracking URL from the route, fetch driver location immediately
  if (_currentTrackingUrl != null && _currentTrackingUrl!.isNotEmpty) {
    debugPrint('🚗 Fetching driver location from provided URL...');
    Future.delayed(const Duration(milliseconds: 500), () {
      _fetchDispatchDriverLocation();
    });
  }
}
```

### 3. Fallback to Order Data
The order details screen will use the tracking URL from:
1. **Route parameter** (if provided and valid)
2. **Order data** (as fallback if not provided via route)

## How It Works

1. **Orders Screen**: When user taps an order, the tracking URL is extracted from the vendor data
2. **URL Encoding**: The URL is encoded using `Uri.encodeComponent()` to handle special characters
3. **Navigation**: The encoded URL is passed as a route parameter
4. **Order Details**: The URL is decoded and validated
5. **Driver Tracking**: The dispatch API is called immediately to fetch driver location

## Example Flow

Original URL:
```
https://dispatch.yabalash.com/order/tracking/976d51/nS7ueT
```

Encoded in route:
```
/order/details/172/https%3A%2F%2Fdispatch.yabalash.com%2Forder%2Ftracking%2F976d51%2FnS7ueT
```

Decoded and used:
```
https://dispatch.yabalash.com/order/tracking/976d51/nS7ueT
```

## Benefits

- ✅ No more routing errors with URLs containing slashes
- ✅ Tracking URL is immediately available when order details open
- ✅ Driver location is fetched right away
- ✅ Fallback to order data if URL not provided via route