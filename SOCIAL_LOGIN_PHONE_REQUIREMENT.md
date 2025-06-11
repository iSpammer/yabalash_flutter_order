# Social Login Phone Number Requirement Implementation

## Overview
Updated the social login implementation to require phone number input before allowing Google/Facebook/Apple sign-in, matching the expected backend behavior.

## Changes Made

### 1. Created Phone Number Dialog Widget
**File**: `/lib/features/auth/widgets/phone_number_dialog.dart`

- Created a modal dialog that appears after successful social authentication
- Shows the user's social profile information (name, email)
- Requires phone number input with country code selection
- Validates phone number format before proceeding
- Returns combined social data with phone information

Key features:
- Provider-specific branding (Google, Facebook, Apple icons and colors)
- Country code picker with default to India (+91)
- Phone number validation
- Non-dismissible dialog (user must enter phone or cancel)
- Loading state during submission

### 2. Updated Login Screen
**File**: `/lib/features/auth/screens/login_screen.dart`

Modified `_handleSocialLogin` method to:
- First authenticate with the social provider
- If successful, show the phone number dialog
- Only proceed with login if phone number is provided
- Show appropriate toast messages for different scenarios

### 3. Updated Auth Service
**File**: `/lib/features/auth/services/auth_service.dart`

Updated `socialLogin` method to include:
- `phone_number`: User's phone number
- `dial_code`: Country dial code (without + prefix)
- `country_code`: Country code (e.g., 'IN')

## API Integration

The social login endpoint now sends:
```json
{
  "auth_id": "social_provider_id",
  "name": "User Name",
  "email": "user@email.com",
  "avatar": "profile_photo_url",
  "phone_number": "9876543210",
  "dial_code": "91",
  "country_code": "IN",
  "device_type": "android/ios",
  "device_token": "fcm_token",
  "fcm_token": "fcm_token",
  "access_token": "social_access_token",
  "id_token": "social_id_token"
}
```

## User Flow

1. User clicks on social login button (Google/Facebook/Apple)
2. Social provider authentication flow executes
3. If successful, phone number dialog appears
4. User enters phone number with country code
5. On submission, complete data is sent to backend
6. User is logged in and redirected to home

## Benefits

- Ensures all users have phone numbers for order tracking and notifications
- Maintains consistency with regular registration flow
- Prevents incomplete user profiles
- Better user communication capabilities

## Testing Recommendations

1. Test with all three social providers (Google, Facebook, Apple)
2. Verify phone number validation works correctly
3. Test cancellation flow
4. Verify country code selection
5. Test with existing and new users
6. Verify error handling for API failures

## Future Enhancements

- Add option to skip phone number (if business requirements change)
- Pre-fill phone number if user has logged in before
- Add SMS OTP verification for phone number
- Support for international phone number formats