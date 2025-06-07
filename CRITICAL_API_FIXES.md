# Critical API Fixes for Yabalash Flutter App

## Issues Fixed

### 1. Cart Add Error - "Invalid product variant"

**Root Cause:**
The Flutter app was missing critical headers that the React Native app sends with every cart API request.

**React Native Headers:**
```javascript
// From React Native app
headers: {
  code: appData.profile.code,        // Country code (e.g., 'SAU')
  currency: currencies.primary_currency.id,  // Currency ID (e.g., '5')
  language: languages.primary_language.id,   // Language ID (e.g., '1')
  systemuser: DeviceInfo.getUniqueId(),     // Device unique ID
}
```

**Fix Applied:**
Updated `cart_service.dart` to include all required headers:
```dart
headers: {
  'systemuser': deviceId,
  'timezone': DateTime.now().timeZoneName,
  'code': 'SAU',     // Country code - should be from app config
  'currency': '5',   // Currency ID - should be from app config  
  'language': language,
}
```

**Important Notes:**
- The React Native app ALWAYS uses the product-level SKU, not the variant SKU
- The variant ID is sent separately as `product_variant_id`
- The `type` parameter (delivery/pickup) is required

### 2. Restaurant Service Error - Response Parsing

**Root Cause:**
The `/vendor/category/list` endpoint returns a list of categories directly, not a map. The Flutter service expected a map structure.

**Fix Applied:**
Updated `restaurant_service.dart` to handle list responses properly:
1. When response is a list (categories), fetch vendor details separately from `/vendor/{id}`
2. Combine vendor data and categories into expected structure
3. Added fallback logic if vendor endpoint fails

**Code Changes:**
```dart
if (response.data is List) {
  // Fetch vendor details separately
  final vendorResponse = await _apiService.get('/vendor/$restaurantId');
  // Combine data
  responseData = {
    'vendor': vendorData,
    'categories': response.data,
  };
}
```

## Testing Instructions

### 1. Test Cart Add to Cart:
```bash
# The app should now properly add products to cart
# Check logs for:
# - "=== ADD TO CART REQUEST ==="
# - Verify SKU is sent (not variant SKU)
# - Verify headers include code, currency, language
```

### 2. Test Restaurant Loading:
```bash
# Navigate to any restaurant/vendor
# Should load without parsing errors
# Check logs for:
# - "Response is a list of categories"
# - "Successfully parsed restaurant"
```

## Next Steps

1. **Configuration Management**: The hardcoded values ('SAU', '5') should come from app configuration
2. **Error Handling**: Add better error messages for specific API errors
3. **Testing**: Test with various products, especially surprise bags that were failing

## API Endpoints Reference

From React Native app:
- Add to cart: `POST /cart/add`
- Get vendor details: `POST /vendor/category/list`
- Get vendor info: `GET /vendor/{id}`

Headers required:
- `code`: Country code
- `currency`: Currency ID
- `language`: Language ID
- `systemuser`: Device unique ID
- `Authorization`: Auth token (if logged in)