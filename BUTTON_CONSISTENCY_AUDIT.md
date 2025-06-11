# Button Consistency Audit - Yabalash Flutter App

## Summary
This audit reveals significant inconsistencies in button implementation across the Flutter app. While a `CustomButton` widget exists with standardized styling, it's not being used consistently throughout the application.

## Key Findings

### 1. CustomButton Implementation
The app has a well-designed `CustomButton` widget (`lib/core/widgets/custom_button.dart`) with:
- Default height: `50.h`
- Default border radius: `12.r`
- Support for loading states
- Support for outlined variants
- Consistent padding: `16.w` horizontal
- Font size: `16.sp` with `FontWeight.w600`

### 2. Inconsistent Button Usage

#### Native Flutter Buttons Still in Use:
- **ElevatedButton**: Found in 20 files
- **OutlinedButton**: Found in 7 files  
- **TextButton**: Found in 22 files

#### Height Inconsistencies:
1. **CustomButton**: Default `50.h`
2. **Order Success Screen**: OutlinedButton with explicit `height: 50.h` wrapper
3. **Product Card**: ElevatedButton with `padding: 8.h` vertical (resulting in ~36-40h total height)
4. **Dialog buttons**: Various TextButtons with no consistent height
5. **Order Card**: OutlinedButton with `padding: 8.h` vertical

#### Styling Inconsistencies:
1. **Border Radius**: 
   - CustomButton: `12.r`
   - Product Card: `6.r`
   - Order Success: `12.r`
   - Various dialogs: Default Material radius

2. **Font Sizes**:
   - CustomButton: `16.sp`
   - Various implementations: `14.sp`, `16.sp`, no explicit size

3. **Font Weight**:
   - CustomButton: `FontWeight.w600`
   - Inconsistent across other implementations

### 3. Files Not Using CustomButton

#### High Priority (User-facing screens):
1. **Auth**: `/features/auth/screens/login_screen.dart` - Uses TextButton, AnimatedAuthButton
2. **Cart**: `/features/cart/screens/cart_screen.dart` - Uses TextButton for "Clear Cart"
3. **Orders**: 
   - `/features/orders/screens/order_success_screen.dart` - Uses OutlinedButton, TextButton
   - `/features/orders/screens/orders_screen.dart` - Uses ElevatedButton
4. **Profile**: `/features/profile/screens/profile_screen.dart` - Uses TextButton
5. **Restaurant/Product**: 
   - `/features/restaurants/widgets/product_card.dart` - Uses ElevatedButton for "ADD" button
   - `/features/restaurants/screens/product_detail_screen.dart` - Uses TextButton

#### Dialog Implementations:
- Most dialogs use TextButton for actions (Cancel, OK, etc.)
- No consistent styling for dialog buttons

### 4. Specific Issues

#### Product Card "ADD" Button:
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
  ),
  // ...
)
```
- Different height, padding, and border radius than CustomButton
- This is a frequently used UI element

#### Order Success Screen:
```dart
SizedBox(
  width: double.infinity,
  height: 50.h,
  child: OutlinedButton(
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: Theme.of(context).primaryColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
    // ...
  ),
)
```
- Manually wrapping with SizedBox instead of using CustomButton
- Duplicating styling logic

#### Login Screen:
- Uses TextButton for "Forgot Password?"
- Uses custom AnimatedAuthButton for main actions
- No use of CustomButton

### 5. Recommendations

1. **Immediate Actions**:
   - Replace all ElevatedButton/OutlinedButton instances with CustomButton
   - Standardize dialog button appearances
   - Update product card "ADD" button to use CustomButton or create specialized variant

2. **CustomButton Enhancements**:
   - Add a `size` parameter (small, medium, large) for different contexts
   - Add `CustomButton.text()` constructor for text-only buttons (replacing TextButton)
   - Consider adding icon-only variant

3. **Style Guide**:
   - Document button usage guidelines
   - Create specific button variants for common use cases (dialog actions, card actions, etc.)

4. **Priority Refactoring**:
   - Product cards (high visibility)
   - Cart/checkout flow
   - Order success screen
   - Login/auth screens

## Files Requiring Updates

### Critical (High User Impact):
1. `lib/features/restaurants/widgets/product_card.dart`
2. `lib/features/cart/screens/cart_screen.dart`
3. `lib/features/orders/screens/order_success_screen.dart`
4. `lib/features/payment/screens/payment_screen.dart` (already uses CustomButton mostly)
5. `lib/features/auth/screens/login_screen.dart`

### Important (Dialogs & Widgets):
1. `lib/features/orders/widgets/cancel_order_dialog.dart`
2. `lib/features/profile/screens/profile_screen.dart`
3. `lib/features/orders/screens/orders_screen.dart`
4. `lib/features/restaurants/screens/product_detail_screen.dart`

### Lower Priority:
- Various dialog implementations
- Less frequently accessed screens