# Google Maps Not Loading - Troubleshooting Guide

## Current Issue
Google Maps is showing a brown/tan background and not loading map tiles.

## Checklist for Google Cloud Console

### 1. Enable Required APIs
Go to [Google Cloud Console](https://console.cloud.google.com/) and ensure these APIs are **ENABLED**:

1. **Maps SDK for Android** ✅ (REQUIRED)
2. **Maps SDK for iOS** ✅ (REQUIRED if using iOS)
3. **Maps JavaScript API** (if using web view)
4. **Places API** (if using place search)
5. **Directions API** (if showing routes)
6. **Geocoding API** (if converting addresses to coordinates)

To enable:
- Go to **APIs & Services** → **Library**
- Search for each API
- Click on it and press **ENABLE**

### 2. Check Billing Account
Google Maps requires an active billing account:
- Go to **Billing** in Google Cloud Console
- Ensure a billing account is linked to your project
- Note: You get $200 free credit monthly

### 3. API Key Configuration
Your new API key: `AIzaSyCHehIUKqyXbRCXQ823_AJ0gZEAY0Bn2Os`

Verify in **APIs & Services** → **Credentials**:
- ✅ Android restrictions are set correctly
- ✅ Package name: `com.yabalash.orderv2`
- ✅ SHA-1: `2A:B4:05:15:46:AB:92:DB:7F:56:98:43:1C:F6:56:56:00:F7:4C:DA`

### 4. API Key Quotas
Check if you're hitting any quotas:
- Go to **APIs & Services** → **Metrics**
- Select "Maps SDK for Android"
- Check for any errors or quota exceeded messages

## Quick Debug Steps

### 1. Check Android Logs
```bash
flutter run
# Then in another terminal:
adb logcat | grep -i "maps\|google"
```

Look for errors like:
- "API key not found"
- "This API project is not authorized"
- "Maps SDK for Android must be enabled"

### 2. Test with Unrestricted Key (Temporary)
1. In Google Cloud Console, edit your API key
2. Under **Application restrictions**, select **None**
3. Save and wait 5 minutes
4. Test the app
5. If it works, the issue is with restrictions

### 3. Check Network
Ensure the device/emulator has internet access:
```bash
adb shell ping google.com
```

### 4. Clean Build
```bash
cd /home/ispam/yabalash_fe_flutter
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

### 5. Check for Conflicting Plugins
Sometimes other plugins can interfere. Check if you have multiple map-related plugins.

## Common Error Messages and Solutions

### "Authorization failure"
- API key is restricted incorrectly
- Wrong SHA-1 fingerprint
- Wrong package name

### "This API project is not authorized to use this API"
- Maps SDK for Android is not enabled
- Billing account not set up

### Brown/Tan Background (No Tiles)
- API not enabled
- Network issues
- API key issues
- Billing/quota issues

## iOS Specific (if applicable)
1. Ensure bundle ID restrictions are set in API key
2. Check Info.plist has proper permissions
3. Verify GoogleService-Info.plist is added

## Final Test
Try this minimal code in your main.dart:
```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MaterialApp(
  home: Scaffold(
    body: GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(24.4539, 54.3773),
        zoom: 10,
      ),
    ),
  ),
));
```

If this doesn't work, the issue is with API configuration, not code.