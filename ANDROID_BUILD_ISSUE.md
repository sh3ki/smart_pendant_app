# Android Build Issue - jlink Error

## Problem Summary
The Smart Pendant app cannot build for Android due to a known incompatibility between:
- Android Gradle Plugin 8.x
- Android Studio's bundled JDK 25
- Android SDK 34/35 `core-for-system-modules.jar`

## Error Message
```
Execution failed for task ':*:compileDebugJavaWithJavac'.
> Could not resolve all files for configuration ':*:androidJdkImage'.
   > Failed to transform core-for-system-modules.jar
      > Error while executing process jlink.exe
```

## Root Cause
The JDK 25 bundled with Android Studio has an incompatible `jlink` tool that cannot process Android SDK 34/35's `core-for-system-modules.jar`. This affects almost all Flutter plugins that compile native Android code.

## Attempted Solutions (All Failed)
1. ❌ Downgraded `geolocator` package
2. ❌ Removed `connectivity_plus` package
3. ❌ Removed `just_audio` package  
4. ❌ Removed `firebase_core` and `firebase_messaging` packages
5. ❌ Cleared Gradle cache multiple times
6. ❌ Reinstalled Gradle wrapper
7. ❌ Updated Java compatibility to 11, then 17
8. ❌ Downgraded to Android SDK 33 (dependencies require SDK 34+)
9. ❌ Modified gradle.properties with various workarounds

## Current Packages Disabled
Due to jlink issues, the following packages are temporarily commented out in `pubspec.yaml`:
- `geolocator` - GPS location services
- `connectivity_plus` - Network connectivity status
- `just_audio` - Audio playback
- `firebase_core` & `firebase_messaging` - Push notifications

## Working Solution

### Option 1: Use JDK 17 from Oracle/Adoptium (RECOMMENDED)
1. Download and install JDK 17 from:
   - Oracle: https://www.oracle.com/java/technologies/downloads/#java17
   - Adoptium: https://adoptium.net/temurin/releases/?version=17

2. Set JAVA_HOME environment variable:
   ```powershell
   [System.Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Path\To\JDK17', 'Machine')
   ```

3. Restart terminal and run:
   ```powershell
   flutter doctor -v
   flutter clean
   flutter run -d emulator-5554
   ```

### Option 2: Switch Android Studio JDK
1. Open Android Studio
2. Go to: **File > Settings > Build, Execution, Deployment > Build Tools > Gradle**
3. Set **Gradle JDK** to JDK 17 (download if not available)
4. Restart Android Studio
5. Rebuild project

### Option 3: Configure gradle.properties
Add to `android/gradle.properties`:
```properties
org.gradle.java.home=C:\\Path\\To\\JDK17
```

## After Fix - Re-enable Packages
Once the build succeeds with a compatible JDK, re-enable the commented packages in `pubspec.yaml` one by one:
1. Uncomment `geolocator: ^10.1.0`
2. Run `flutter pub get`
3. Test build
4. Repeat for `connectivity_plus`, `just_audio`, `firebase_core`, etc.

## References
- [Flutter Issue #149068](https://github.com/flutter/flutter/issues/149068)
- [Android Gradle Plugin Known Issues](https://developer.android.com/studio/known-issues)
- [Stack Overflow: jlink error with Android SDK 34](https://stackoverflow.com/questions/77471345)

## Current Project Status
- ✅ Complete Flutter app with 7 screens
- ✅ Riverpod state management
- ✅ Mock real-time telemetry
- ✅ Unit tests passing
- ✅ Code analysis clean
- ⚠️ Android build blocked by JDK/jlink issue
- 🔄 Temporary workaround: Disabled GPS, audio, notifications, connectivity features

## Next Steps
1. Install JDK 17 from Oracle or Adoptium
2. Configure JAVA_HOME or gradle.properties
3. Clean and rebuild project
4. Re-enable disabled packages
5. Deploy to emulator-5554
