# Android Configuration Guide

## Permissions

Add the following to `android/app/src/main/AndroidManifest.xml` inside the `<manifest>` tag (before `<application>`):

```xml
<!-- Internet access for API calls -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Location permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

<!-- Audio recording (for ambient audio playback) -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>

<!-- Push notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

## Google Maps API Key

Add inside the `<application>` tag in `AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

## Minimum SDK Version

Update `android/app/build.gradle`:

```gradle
android {
    ...
    defaultConfig {
        ...
        minSdkVersion 21  // Minimum for most features
        targetSdkVersion 34
    }
}
```

## Firebase Configuration

1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/` directory
3. Ensure `android/build.gradle` has:
   ```gradle
   buildscript {
       dependencies {
           classpath 'com.google.gms:google-services:4.4.0'
       }
   }
   ```
4. Ensure `android/app/build.gradle` has:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

## ProGuard Rules (Release builds)

Add to `android/app/proguard-rules.pro`:

```
# Keep Google Maps classes
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Dio HTTP client
-keep class io.flutter.plugins.** { *; }
```

## Testing Location in Emulator

Use ADB to simulate GPS:
```bash
adb shell
geo fix -122.4194 37.7749
```

Or use the emulator's Extended Controls (three dots) → Location → Set location.
