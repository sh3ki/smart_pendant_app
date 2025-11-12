# Quick Start Guide - Smart Pendant App

This is a **5-minute quick start** to get the app running on your device.

## Prerequisites Check

```powershell
flutter doctor
```

Make sure you have:
- ✅ Flutter SDK installed
- ✅ Android toolchain OR Xcode (for iOS)
- ✅ At least one device/emulator connected

## Step 1: Install Dependencies (1 min)

```powershell
cd c:\smart_pendant_app
flutter pub get
```

## Step 2: Configure Environment (1 min)

The app already has a default `.env` file. For now, you can use the mock backend URLs that are already configured.

**Optional:** Add your Google Maps API key to `.env`:
```
GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE
```

> **Note:** The app will work without a real Maps key (it will just show a "Development only" watermark on the map).

## Step 3: Run the App (1 min)

```powershell
# Check connected devices
flutter devices

# Run on the first available device
flutter run

# Or specify a device
flutter run -d <device_id>
```

## Step 4: Explore the App (2 min)

Once running, you'll see:

1. **Home Dashboard** - Shows device status, battery, location
   - Tap "Map" to see GPS tracking
   - Tap "Camera" to request snapshots
   - Tap "Listen" for audio monitoring
   - Tap "Activity" for motion tracking
   - Tap the red "SOS Alerts" button

2. **Mock Data** - The app generates fake telemetry every 5 seconds:
   - GPS coordinates slowly change
   - Motion state changes between rest/walk/run
   - Battery stays around 70-80%

3. **All Features Work** - You can:
   - Request camera snapshots (shows placeholder images)
   - Start/stop audio listening
   - View activity charts
   - Mark SOS alerts as handled
   - Change settings

## What You're Seeing

- **Mocked Backend:** All data is generated locally (no real pendant)
- **Real-time Updates:** Telemetry updates every 5 seconds
- **Full UI:** All 7 screens are complete and navigable
- **State Management:** Riverpod providers handle all state

## Next: Connect to Real Backend

To connect to your backend server:

1. Edit `.env` and update:
   ```
   API_BASE_URL=https://your-backend.com
   WS_URL=wss://your-backend.com
   ```

2. Update providers to use `ApiClient` instead of mocks (see `DELIVERY_SUMMARY.md`)

3. Restart the app

## Troubleshooting

### "No devices found"
```powershell
# For Android emulator
flutter emulators --launch <emulator_id>

# For iOS simulator (macOS only)
open -a Simulator
```

### Build errors
```powershell
flutter clean
flutter pub get
flutter run
```

### Google Maps not showing
- This is expected without a real API key
- The map will work but show a watermark
- Get a free key at: https://console.cloud.google.com

## Run Tests

```powershell
flutter test
```

Should output: `All tests passed!`

## Build Release

```powershell
# Android APK
flutter build apk --release

# iOS (macOS only)
flutter build ios --release
```

---

**That's it!** You now have a fully functional Smart Pendant app running locally with mocked data.

For detailed documentation, see:
- `README.md` - Complete project docs
- `DELIVERY_SUMMARY.md` - Implementation details
- `docs/ANDROID_SETUP.md` - Android config
- `docs/IOS_SETUP.md` - iOS config
