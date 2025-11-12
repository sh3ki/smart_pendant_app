# iOS Configuration Guide

## Info.plist Permissions

Add the following keys to `ios/Runner/Info.plist`:

```xml
<!-- Location permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show your child's pendant location on the map</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs background location to continuously track your child's pendant</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs location access to track your child's pendant even when the app is in the background</string>

<!-- Microphone for audio playback -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to play ambient audio from your child's pendant</string>

<!-- User tracking (if analytics are used) -->
<key>NSUserTrackingUsageDescription</key>
<string>This app uses tracking to improve your experience</string>

<!-- Background modes -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Google Maps Configuration

1. Get your iOS API key from Google Cloud Console
2. Edit `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Firebase Configuration

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to `ios/Runner/` directory using Xcode (drag and drop)
3. Ensure it's added to the Runner target

## Minimum iOS Version

Update `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

Update `ios/Runner.xcodeproj/project.pbxproj` (or use Xcode):
- Set iOS Deployment Target to 13.0

## Capabilities (in Xcode)

Open `ios/Runner.xcworkspace` in Xcode, select Runner target:

1. **Signing & Capabilities**:
   - Add "Background Modes" capability
     - Check "Location updates"
     - Check "Remote notifications"
     - Check "Background fetch"
   - Add "Push Notifications" capability

2. **Background fetch**:
   - Enable for periodic updates

## Testing on iOS Simulator

1. Run app on simulator
2. To simulate location:
   - Debug menu → Location → Custom Location
   - Enter latitude/longitude: 37.7749, -122.4194

## App Transport Security

If your backend doesn't use HTTPS, add to Info.plist (NOT RECOMMENDED for production):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## CocoaPods Installation

If pods are not installed:

```bash
cd ios
pod install
cd ..
```

## Common Issues

### Google Maps not showing
- Verify API key is correct in AppDelegate.swift
- Enable "Maps SDK for iOS" in Google Cloud Console
- Check billing is enabled

### Push notifications not working
- Ensure APNs certificates are configured in Firebase
- Test with physical device (push doesn't work in simulator)
- Check capabilities are enabled

### Build errors with pods
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```
