# Google Maps Fix Required

## Issue
The Google Maps is showing a brown/tan background because the Maps SDK is not properly configured in Google Cloud Console.

## Solution Steps

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Select your project (or create a new one)

2. **Enable Required APIs**
   Navigate to **APIs & Services** → **Library** and enable:
   - ✅ Maps SDK for Android (REQUIRED)
   - ✅ Maps SDK for iOS (if building for iOS)
   - ✅ Maps JavaScript API (optional, for web)

3. **Check Billing**
   - Ensure a billing account is linked (Google provides $200 free monthly credit)
   - Go to **Billing** → **Link a billing account**

4. **Verify API Key Configuration**
   The app is using API key: `AIzaSyCHehIUKqyXbRCXQ823_AJ0gZEAY0Bn2Os`
   
   Go to **APIs & Services** → **Credentials** and verify:
   - The API key exists
   - It has Android restrictions set with:
     - Package name: `com.yabalash.orderv2`
     - SHA-1: `2A:B4:05:15:46:AB:92:DB:7F:56:98:43:1C:F6:56:56:00:F7:4C:DA`

5. **Test the Fix**
   ```bash
   flutter clean
   cd android && ./gradlew clean && cd ..
   flutter pub get
   flutter run
   ```

## Temporary Workaround
Until the Google Cloud setup is complete, the app will show:
- Driver info section with mock data
- Order status timeline
- Embedded tracking WebView (when URL is available)
- Placeholder for map sections

## Notes
- The brown background is NOT a code issue
- It's a Google Cloud Console configuration issue
- Once the Maps SDK for Android is enabled, maps will display correctly
- This usually takes effect within 5 minutes of enabling the API