# React Native App Registration and OTP Verification Flow Analysis

## Overview
This document analyzes the registration and OTP verification flow in the React Native app located at `/home/ispam/order_app-1`.

## API Base URL
- Production: `https://yabalash.com/api/v1`

## Registration Flow

### 1. Registration Screen (`src/Screens/Signup/Signup.js`)

#### Key Components:
- **Form Fields**:
  - Name (required)
  - Email (required)
  - Phone Number with country code (required)
  - Password (required)
  - Referral Code (optional)
  - Additional KYC fields if enabled (Aadhaar, Bank details, etc.)

#### Registration Process:
1. User fills out the registration form
2. Form validation includes:
   - Name validation: `/^[a-zA-Z'' ]{2,50}$/`
   - Email validation: Standard email regex
   - Password validation
   - Phone number validation

3. **API Call**: `POST /auth/register`
   ```javascript
   // Form data includes:
   formdata.append('name', name);
   formdata.append('phone_number', phoneNumber);
   formdata.append('dial_code', callingCode);
   formdata.append('country_code', cca2);
   formdata.append('email', email);
   formdata.append('password', password);
   formdata.append('device_type', Platform.OS);
   formdata.append('device_token', DeviceInfo.getUniqueId());
   formdata.append('fcm_token', fcmToken);
   ```

4. **Response Handling**:
   ```javascript
   const checkEmailPhoneVerified = (data) => {
     if (
       !!(!!data?.client_preference?.verify_email && !data?.verify_details?.is_email_verified) ||
       !!(!!data?.client_preference?.verify_phone && !data?.verify_details?.is_phone_verified)
     ) {
       // Navigate to verification screen
       moveToNewScreen(navigationStrings.VERIFY_ACCOUNT, data)();
     } else {
       // Direct login if verification not required
       successSignUp(data);
     }
   };
   ```

### 2. OTP Verification Screen (`src/Screens/VerifyAccount/VerifyAccount.js`)

#### Navigation:
- After successful registration, if phone/email verification is required, the app navigates to `VERIFY_ACCOUNT` screen
- The entire registration response data is passed as route params

#### Verification Process:

1. **Auto-trigger OTP on Screen Load**:
   ```javascript
   useEffect(() => {
     if (!!phoneNumber && !!paramsData?.client_preference?.verify_phone && 
         !paramsData?.verify_details?.is_phone_verified) {
       sendOTP('phone');
     }
     if (!!email && !!paramsData?.client_preference?.verify_email && 
         !paramsData?.verify_details?.is_email_verified) {
       sendOTP('email');
     }
   }, []);
   ```

2. **Send OTP API**: `POST /auth/sendToken`
   ```javascript
   const sendOTP = (type) => {
     let data = {};
     if (type == 'phone') {
       data['phone_number'] = phoneNumber;
       data['dial_code'] = callingCode;
       data['type'] = type;
     } else {
       data['email'] = email;
       data['type'] = type;
     }
     // API call with auth token from registration response
     actions.resendOTP(data, {
       code: appData?.profile?.code,
       authorization: paramsData?.auth_token,
     });
   };
   ```

3. **OTP Input**:
   - Uses `SmoothPinCodeInput` component
   - 6-digit OTP code
   - Auto-capture OTP on Android using `RNOtpVerify`

4. **Verify OTP API**: `POST /auth/verifyAccount`
   ```javascript
   const onVerify = (type, otp) => {
     let data = {};
     data['type'] = type; // 'phone' or 'email'
     data['otp'] = otp;
     if (type == 'phone') {
       data['phone_number'] = phoneNumber;
     }
     // API call with auth token
     actions.verifyAccount(data, {
       code: appData?.profile?.code,
       authorization: paramsData?.auth_token,
     });
   };
   ```

5. **Success Flow**:
   - On successful verification, user data is saved and user is logged in
   - The app saves user data to AsyncStorage and Redux store

## Alternative Login Flow

### Phone Number Login (`src/Screens/OtpVerification/OtpVerification.js`)
- Used for direct phone number login without registration
- **API**: `POST /auth/loginViaUsername` (to send OTP)
- **API**: `POST /auth/verify/phoneLoginOtp` (to verify OTP)

## Key API Endpoints Summary

1. **Registration**: `POST /api/v1/auth/register`
2. **Send OTP**: `POST /api/v1/auth/sendToken`
3. **Verify Account**: `POST /api/v1/auth/verifyAccount`
4. **Resend OTP**: `POST /api/v1/auth/sendToken` (same endpoint)
5. **Phone Login**: `POST /api/v1/auth/loginViaUsername`
6. **Phone Login OTP Verify**: `POST /api/v1/auth/verify/phoneLoginOtp`

## Important Notes

1. **Auth Token**: The registration response includes an `auth_token` that must be used for subsequent OTP-related API calls
2. **Auto-navigation**: The app automatically navigates to OTP verification if required by server settings
3. **Verification Types**: Both email and phone verification can be enabled/disabled by server preferences
4. **Timer**: 30-second timer for OTP resend functionality
5. **Android OTP Auto-read**: Implemented using `react-native-otp-verify` library

## Flutter App Implementation Considerations

1. **Registration Response**: Must handle the registration response to check if verification is required
2. **Navigation**: Implement automatic navigation to OTP screen based on verification requirements
3. **Auth Token Storage**: Store the auth token from registration response for OTP API calls
4. **OTP Auto-trigger**: Automatically send OTP when verification screen loads
5. **Verification State**: Track whether email/phone is already verified from the registration response