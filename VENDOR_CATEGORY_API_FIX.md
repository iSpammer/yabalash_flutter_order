# Vendor Category API Fix

## Problem
The "Restaurants" category (ID: 28) was showing empty results because it was using the wrong API endpoint. The `/category/{id}` endpoint returns empty data for vendor categories.

## Solution
Discovered and implemented the correct API endpoint from the Postman collection: `/api/v1/get/subcategory/vendor`

### Changes Made:

1. **Updated CategoryService** (`lib/features/categories/services/category_service.dart`)
   - Added logic to detect vendor categories (currently hardcoded for category ID 28)
   - Implemented `_getVendorsForCategory()` method that uses the `/get/subcategory/vendor` endpoint
   - This endpoint requires:
     - `category_id`
     - `type` (delivery/pickup)
     - `latitude` and `longitude` (optional but recommended)
     - `open_vendor`, `close_vendor`, `best_vendor` flags

2. **Enhanced CategoryProvider** (`lib/features/categories/providers/category_provider.dart`)
   - Added `_deliveryType` field to track delivery mode
   - Added `setDeliveryType()` method
   - Updated `loadProducts()` to pass delivery type to service

3. **Updated CategoryScreen** (`lib/features/categories/screens/category_screen.dart`)
   - Gets delivery mode from DashboardProvider
   - Gets location coordinates from DashboardProvider
   - Sets these values in CategoryProvider before loading data

### How It Works:

1. When loading category 28 (Restaurants), the service detects it's a vendor category
2. Instead of calling `/category/28`, it calls `/get/subcategory/vendor` with:
   ```json
   {
     "category_id": 28,
     "type": "delivery",
     "latitude": "user_lat",
     "longitude": "user_lng",
     "open_vendor": 1,
     "close_vendor": 0,
     "best_vendor": 0
   }
   ```
3. The response is transformed to match the expected structure
4. Vendors are displayed using the VendorGrid widget

### Testing:
1. Make sure location permissions are granted
2. Click on "Restaurants" category
3. Should now see a list of restaurants/vendors (if any are available in your area)

### Future Improvements:
- Make the vendor category detection dynamic (check category metadata instead of hardcoding IDs)
- Add more vendor category IDs as needed
- Implement vendor-specific filters (open now, delivery time, etc.)