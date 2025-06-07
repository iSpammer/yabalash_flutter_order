# Vendor Conflict Dialog Fix

## Issue
When adding an item from a different vendor from the dashboard, users were getting an error message saying they have items from a different vendor, but the vendor conflict dialog (with options to browse current restaurant or clear cart) was not showing.

## Root Cause
The vendor conflict check was only comparing against `currentVendorId`, which might not be set if the cart hasn't been loaded yet. Additionally, when the server returned a vendor conflict error, it was only showing as a snackbar error instead of the dialog.

## Solution

### 1. Improved Vendor Conflict Detection
Added a new method to CartProvider:
```dart
bool hasItemsFromDifferentVendor(int vendorId) {
  if (_cartData == null || _cartData!.products.isEmpty) return false;
  
  // Check if any vendor in cart is different from the provided vendorId
  for (var vendor in _cartData!.products) {
    if (vendor.vendorId != null && vendor.vendorId != vendorId) {
      return true;
    }
  }
  return false;
}
```

### 2. Updated Client-Side Check
Changed the vendor conflict check in `_handleAddToCart`:
```dart
// Before
if (cartProvider.currentVendorId != null &&
    cartProvider.currentVendorId != product.vendorId) {
  _showVendorConflictDialog(context, product, cartProvider);
  return;
}

// After
if (cartProvider.hasItemsFromDifferentVendor(product.vendorId ?? 0)) {
  _showVendorConflictDialog(context, product, cartProvider);
  return;
}
```

### 3. Server-Side Error Handling
Added logic to detect vendor conflict errors from the server and show the dialog:
```dart
if (!success) {
  final errorMsg = cartProvider.errorMessage ?? 'Failed to add item to cart';
  if (errorMsg.toLowerCase().contains('vendor') || 
      errorMsg.toLowerCase().contains('another vendor') ||
      errorMsg.toLowerCase().contains('existing items')) {
    // Show vendor conflict dialog instead of just error snackbar
    _showVendorConflictDialog(context, product, cartProvider);
  } else {
    // Show regular error snackbar
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

## Result
Now when users try to add items from a different vendor:
1. The vendor conflict is detected on the client side first (if cart data is loaded)
2. If not detected client-side, the server error is caught and the dialog is shown
3. Users see the proper dialog with options to:
   - Browse current restaurant
   - Clear cart & add new item (with addon selection if needed)

## Testing
Test with:
1. Add item from Vendor A
2. Try to add item from Vendor B from dashboard
3. Should see vendor conflict dialog, not just error message
4. Test both "Browse Current Restaurant" and "Clear Cart & Add" options
5. Verify addon selection still works when clearing cart