# Cart Loading Dialog Fix

## Issue
When adding a product to cart from the dashboard that causes a vendor conflict:
1. The vendor conflict dialog appears
2. User clicks "Clear Cart & Add"
3. A loading dialog shows "Clearing cart and loading product details..."
4. The cart is cleared and product is added successfully
5. BUT the loading dialog remains stuck on screen

## Root Cause
The loading dialog shown during the vendor conflict resolution was not being properly closed after the operation completed successfully.

## Solution
1. **Forced Dialog Closure**: Changed all `CartLoadingDialog.hide()` calls to `CartLoadingDialog.hideForce()` in the vendor conflict handler to ensure immediate closure
2. **Improved Dialog Management**: Added proper dialog closure before showing success/error messages
3. **Fixed Syntax Issues**: Corrected missing braces and indentation in the vendor conflict dialog handler

## Key Changes

### In `section_widget_factory.dart` - `_showVendorConflictDialog` method:

1. Used `CartLoadingDialog.hideForce()` instead of `hide()` for all dialog closures
2. Added small delays between dialog closure and showing snackbars to prevent UI conflicts
3. Ensured dialog is closed in all code paths (success, failure, and exception)

### In `CartLoadingDialog` - improved `hideForce` method:

1. Better detection of popup routes (dialogs) using `PopupRoute` type
2. Added safety counter to prevent infinite loops
3. Added error handling for navigation errors

## Testing
To test the fix:
1. Add a product from one vendor to cart
2. Try to add a product from a different vendor
3. Click "Clear Cart & Add" in the vendor conflict dialog
4. Verify the loading dialog closes properly after the product is added