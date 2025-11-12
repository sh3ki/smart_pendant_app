# Smart Pendant Parent App

A cross-platform (Android + iOS) Flutter mobile application for monitoring a Smart Pendant wearable device. Provides real-time location tracking, camera snapshots, ambient audio monitoring, activity status, and SOS alert handling.

## Features

✅ **Real-time Location Tracking** - Interactive map with GPS breadcrumb trail  
✅ **Live Camera Snapshots** - Request and auto-refresh pendant camera images  
✅ **Ambient Audio Monitoring** - One-way audio streaming from pendant  
✅ **Activity Tracking** - Monitor motion state (rest/walk/run) with charts  
✅ **SOS Alerts** - Instant push notifications with location and quick actions  
✅ **Device Health** - Battery, signal strength, online/offline status  
✅ **Configurable Settings** - Image quality, telemetry frequency, notifications  

## Tech Stack

- **Flutter** 3.16+ / Dart 3.2+
- **State Management**: Riverpod 2.5
- **Maps**: Google Maps Flutter
- **HTTP**: Dio
- **Real-time**: WebSocket Channel & MQTT Client
- **Push Notifications**: Firebase Cloud Messaging
- **Audio**: Just Audio
- **Charts**: FL Chart
- **Storage**: Flutter Secure Storage, Shared Preferences, Hive

## Prerequisites

- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / Xcode (for mobile builds)
- Google Maps API Key (for map features)
- Firebase project (for push notifications)

## Installation & Setup

### 1. Clone and Install Dependencies

```powershell
cd c:\smart_pendant_app
flutter pub get
```

### 2. Configure Environment Variables

Create a `.env` file in the project root (copy from `.env.dev`):

```
API_BASE_URL=https://api-dev.smartpendant.example.com
WS_URL=wss://ws-dev.smartpendant.example.com
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY_HERE
```

### 3. Configure Google Maps API

**Android**: Edit `android/app/src/main/AndroidManifest.xml` and add:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

**iOS**: Edit `ios/Runner/AppDelegate.swift` and add your key in the `didFinishLaunchingWithOptions` method.

### 4. Firebase Setup (for push notifications)

1. Create a Firebase project at https://console.firebase.google.com
2. Add Android and iOS apps to your Firebase project
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place them in `android/app/` and `ios/Runner/` respectively
5. Follow the FlutterFire CLI setup: `flutterfire configure`

### 5. Run the App

```powershell
# Run on connected device/emulator
flutter run

# Run in release mode
flutter run --release

# Specify device
flutter run -d <device_id>
```

## Project Structure (Current Implementation)

```
lib/
├── main.dart                    # App entry point with Riverpod
├── models/
│   ├── app_models.dart          # Telemetry, Device, Camera, Audio, SOS, Settings models
│   └── device.dart              # Legacy device model
├── providers/
│   ├── telemetry_provider.dart  # Real-time telemetry with mock stream
│   ├── location_history_provider.dart  # GPS breadcrumb trail
│   ├── camera_provider.dart     # Snapshot requests & auto-refresh
│   ├── audio_provider.dart      # Audio streaming state
│   ├── activity_provider.dart   # Activity history tracking
│   ├── sos_provider.dart        # SOS alerts management
│   ├── device_provider.dart     # Device online status
│   └── settings_provider.dart   # App configuration
├── screens/
│   ├── home_screen.dart         # Main dashboard
│   ├── map_screen.dart          # Full-screen map with breadcrumb
│   ├── camera_screen.dart       # Camera snapshot view
│   ├── audio_screen.dart        # Audio listening interface
│   ├── activity_screen.dart     # Activity charts & history
│   ├── sos_screen.dart          # SOS alerts list
│   └── settings_screen.dart     # Settings configuration
└── services/
    ├── api_client.dart          # REST API client (Dio)
    ├── websocket_service.dart   # WebSocket real-time updates
    └── mock_device_service.dart # Mock data (legacy)
```

## Current Implementation Status

### ✅ Completed
- Home dashboard with device status
- Real-time telemetry updates (mocked, updates every 5s)
- Interactive Google Maps with GPS breadcrumb trail
- Camera snapshot view with manual request & auto-refresh
- Audio listening interface with play/stop controls
- Activity tracking with line chart visualization
- SOS alerts screen with mark-as-handled functionality
- Settings screen for image quality & notification preferences
- Riverpod state management throughout
- API client structure ready for backend integration
- WebSocket service for real-time events

### 🚧 In Progress / TODO
- Connect API client to real backend endpoints
- Integrate WebSocket for live telemetry (currently mocked)
- Implement Firebase Cloud Messaging for push notifications
- Add just_audio player for actual audio chunk playback
- Implement permission_handler flows (location, microphone, notifications)
- Add cached_network_image for efficient image caching
- Persist settings to shared_preferences
- Add offline caching with Hive
- Unit tests for providers
- Widget tests for screens
- Integration tests for real-time flows

## Running Tests

```powershell
# Unit tests
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests (requires device/emulator)
flutter test integration_test
```

## Building for Production

### Android APK
```powershell
flutter build apk --release
```

### Android App Bundle
```powershell
flutter build appbundle --release
```

### iOS
```powershell
flutter build ios --release
```

## Backend Integration

The app is designed to work with a backend that provides:

### REST API Endpoints
- `POST /auth/login` - User authentication (optional, app currently has no login)
- `GET /devices` - List devices (currently hardcoded to single device)
- `GET /devices/{id}/telemetry` - Get latest telemetry
- `GET /devices/{id}/latest-image` - Get latest snapshot URL
- `POST /devices/{id}/command` - Send commands (capture_snapshot, start_audio, stop_audio)
- `GET /devices/{id}/alerts` - Get SOS alerts
- `POST /devices/{id}/alerts/{alertId}/acknowledge` - Mark alert as handled

### WebSocket Topics
- `devices/{deviceId}/telemetry` - Real-time telemetry updates
- `devices/{deviceId}/image-available` - New image available notifications
- `devices/{deviceId}/alerts` - SOS alert events

### Mock Data
Currently the app uses mocked data providers that simulate:
- GPS telemetry updating every 5 seconds
- Random motion states (rest/walk/run)
- Image URLs from placeholder service (picsum.photos)
- Historical SOS alerts

To switch to real backend, update `.env` with actual API URLs and the providers will use `ApiClient` and `WebSocketService`.

## Configuration

Edit `.env` files for different environments:
- `.env.dev` - Development environment
- `.env.staging` - Staging environment  
- `.env.prod` - Production environment

## Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show your child's pendant location</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs background location to track your child's pendant</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to play ambient audio from the pendant</string>
```

## Troubleshooting

### Flutter not found
Ensure Flutter is added to your PATH. Run `flutter doctor` to verify installation.

### Google Maps not displaying
- Verify your Google Maps API key is correct in `.env` and platform-specific configs
- Enable Maps SDK for Android/iOS in Google Cloud Console
- Check billing is enabled on your Google Cloud project

### WebSocket connection fails
- Ensure backend WebSocket server is running
- Check firewall/network allows WebSocket connections
- Verify WS_URL in `.env` is correct

### Build errors
```powershell
flutter clean
flutter pub get
flutter pub upgrade
```

## Contributing

This is a complete implementation of the Smart Pendant Parent App based on the project brief. The app follows Flutter best practices with:
- Clean architecture (presentation/domain/data layers)
- Riverpod for state management
- Modular provider-based architecture
- Comprehensive error handling
- Offline-first considerations

## License

Proprietary - Smart Pendant Project

## Contact & Support

For questions or issues, please refer to the project documentation or contact the development team.

---

**Note**: This app currently uses mocked data for development. To connect to a real backend, update the environment variables and ensure the backend implements the API contracts described in the project brief.

## Architecture

The app follows **Clean Architecture** principles with three main layers:

1. **Presentation Layer**: UI components (screens, widgets) and state management (Riverpod/BLoC)
2. **Domain Layer**: Business logic, entities, and use cases
3. **Data Layer**: API clients, data sources, and repository implementations

### State Management
- **Primary**: Riverpod (recommended) or BLoC pattern
- Separation of concerns with providers/blocs for each feature
- Dependency injection for services and repositories

## Features & Screens

### 1. Authentication
- Email/password sign-in and sign-up
- Secure token storage (JWT)
- Token refresh mechanism
- Password recovery

### 2. Device List (Home)
- List of paired pendant devices
- Real-time status indicators (online/offline)
- Battery level, signal strength, last seen
- Quick action buttons (locate, camera, listen)
- SOS notification badges

### 3. Device Detail
- Device overview with key metrics
- Map preview with current location
- Quick access to camera, audio, and SOS info
- Activity summary
- Pull-to-refresh

### 4. Live Map
- Full-screen interactive map (Google Maps/Mapbox)
- Real-time location marker
- Breadcrumb trail (last N positions)
- Navigation integration
- Geofence visualization (future)

### 5. Camera View
- Latest snapshot display
- Manual "Request Snapshot" button
- Auto-refresh toggle (configurable interval 1-5s)
- Timestamp overlay
- Image caching

### 6. Audio Monitoring
- One-way ambient audio listening
- Start/stop controls
- Audio visualizer
- Buffering indicator
- Network quality indicator

### 7. Activity/History
- Current motion state (rest/walk/run)
- Activity timeline/chart
- Historical data view
- Export functionality

### 8. SOS Alerts
- Push notification handling
- SOS detail screen with map
- Quick actions: navigate, call, acknowledge
- Alert history

### 9. Settings
- Device configuration (telemetry frequency, image quality)
- Account management
- Notification preferences
- Privacy & permissions
- Sign out

## API Integration

### REST Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/auth/login` | User authentication |
| POST | `/api/auth/signup` | User registration |
| GET | `/api/devices` | Fetch device list |
| GET | `/api/devices/{id}` | Fetch device details |
| GET | `/api/devices/{id}/latest-image` | Get latest snapshot |
| POST | `/api/devices/{id}/command` | Send command to device |
| GET | `/api/devices/{id}/telemetry` | Fetch telemetry history |
| POST | `/api/devices/{id}/alert/acknowledge` | Acknowledge SOS alert |

### Real-Time Communication

**WebSocket Topics** (or MQTT):
- `devices/{deviceId}/telemetry` - Real-time location & status
- `devices/{deviceId}/image-available` - New snapshot notifications
- `devices/{deviceId}/alerts` - SOS and critical alerts
- `devices/{deviceId}/audio-chunk` - Audio stream chunks

**Fallback**: Polling every 15-30 seconds if WebSocket unavailable

## Key Packages

### Core Functionality
- `flutter_riverpod` or `flutter_bloc` - State management
- `dio` - HTTP client with interceptors
- `web_socket_channel` or `mqtt_client` - Real-time communication
- `firebase_messaging` - Push notifications (FCM/APNs)

### UI & Media
- `google_maps_flutter` or `flutter_map` - Interactive maps
- `cached_network_image` - Image caching
- `just_audio` or `audioplayers` - Audio playback
- `fl_chart` - Activity charts

### Device Features
- `permission_handler` - Runtime permissions
- `geolocator` - Device location (if needed)
- `url_launcher` - External navigation
- `share_plus` - Share location/data

### Storage & Security
- `flutter_secure_storage` - Secure token storage
- `hive` or `shared_preferences` - Local cache
- `path_provider` - File system access

### Development
- `flutter_test` - Unit testing
- `mockito` - Mocking for tests
- `integration_test` - End-to-end tests
- `flutter_launcher_icons` - App icon generation
- `flutter_native_splash` - Splash screen

## Setup Instructions

### Prerequisites
- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / Xcode
- Android SDK (API 21+) / iOS 12.0+
- Firebase project (for FCM)
- Map API key (Google Maps or Mapbox)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smart_pendant_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   
   Create `.env` file in project root:
   ```
   API_BASE_URL=https://api.smartpendant.com
   WEBSOCKET_URL=wss://api.smartpendant.com/ws
   GOOGLE_MAPS_API_KEY=your_maps_api_key
   ```

4. **Configure Firebase**
   
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`
   - Follow Firebase setup instructions in `docs/firebase_setup.md`

5. **Configure Maps API**
   
   **Android**: Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="${GOOGLE_MAPS_API_KEY}"/>
   ```
   
   **iOS**: Add to `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_API_KEY")
   ```

6. **Run the app**
   ```bash
   # Development
   flutter run --dart-define=ENV=dev
   
   # Production
   flutter run --dart-define=ENV=prod --release
   ```

## Platform-Specific Configuration

### Android

**Required Permissions** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

**Min SDK**: 21 (Android 5.0)
**Target SDK**: 34 (Android 14)

### iOS

**Info.plist Keys** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show your child's pendant on the map</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need background location to continuously track your child's pendant</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to play ambient audio from the pendant</string>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>audio</string>
</array>
```

**Min iOS Version**: 12.0
**Target iOS Version**: 17.0

## Development Workflow

### Running Tests

```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widgets/

# Integration tests
flutter test integration_test/

# Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Code Generation

```bash
# Generate code (freezed, json_serializable, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (during development)
flutter pub run build_runner watch
```

### Linting

```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Check formatting
flutter format --set-exit-if-changed lib/
```

## Environment Configuration

The app supports multiple environments (dev, staging, prod):

```bash
# Development
flutter run --dart-define=ENV=dev

# Staging
flutter run --dart-define=ENV=staging

# Production
flutter run --dart-define=ENV=prod --release
```

Environment-specific configuration in `lib/core/config/env_config.dart`

## Build & Release

### Android APK/AAB

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS IPA

```bash
# Build for simulator
flutter build ios --debug --simulator

# Build for device (requires code signing)
flutter build ios --release

# Create IPA (via Xcode or fastlane)
# See docs/ios_release.md
```

## Security & Privacy

### Authentication
- JWT tokens with short expiry (15 min access, 7 day refresh)
- Secure storage using `flutter_secure_storage`
- Automatic token refresh

### Data Protection
- HTTPS/TLS for all communication
- Certificate pinning (optional, configurable)
- No sensitive data in logs (production)
- Biometric authentication option (future)

### Privacy Compliance
- Clear permission rationales
- Privacy policy link in app
- Data deletion option
- GDPR/CCPA compliant

## Performance Optimization

### Network
- Image caching (avoid repeated downloads)
- Debounced API calls
- Request cancellation on screen exit
- Adaptive quality (cellular vs WiFi)

### Battery
- Reduce polling frequency when battery low
- Background task optimization
- Efficient location updates

### Memory
- Lazy loading for lists
- Image memory cache limits
- Dispose streams and controllers

## Troubleshooting

### Common Issues

**Issue**: Maps not showing
- **Solution**: Verify API key is configured correctly and billing is enabled

**Issue**: Push notifications not working
- **Solution**: Check Firebase configuration and APNs certificates

**Issue**: WebSocket connection fails
- **Solution**: Verify WSS URL and fallback to polling

**Issue**: Background location not working (iOS)
- **Solution**: Ensure background modes are enabled and permissions granted

See `docs/troubleshooting.md` for detailed solutions.

## Contributing

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Follow code style guidelines (see `docs/coding_standards.md`)
3. Write tests for new features
4. Run linter and tests before commit
5. Submit pull request with clear description

## Testing Strategy

### Unit Tests
- State management logic (providers/blocs)
- Repository implementations
- Use cases and business logic
- Utility functions

### Widget Tests
- Screen rendering
- User interactions
- State updates
- Error states

### Integration Tests
- End-to-end user flows
- API integration (with mock server)
- Real-time communication
- Push notification handling

Target coverage: **80%** minimum

## CI/CD

GitHub Actions workflows (`.github/workflows/`):
- `ci.yml` - Lint, test, build on pull requests
- `cd_android.yml` - Deploy to Play Store
- `cd_ios.yml` - Deploy to App Store

See `docs/ci_cd_setup.md` for configuration details.

## Documentation

- `docs/api_integration.md` - Backend API details
- `docs/architecture.md` - Architecture deep dive
- `docs/state_management.md` - State management patterns
- `docs/firebase_setup.md` - Firebase configuration
- `docs/maps_setup.md` - Maps integration
- `docs/push_notifications.md` - FCM/APNs setup
- `docs/testing_guide.md` - Testing best practices
- `docs/deployment.md` - Release process
- `docs/wireframes/` - UI/UX mockups

## Support & Contact

- **Issues**: GitHub Issues
- **Documentation**: `/docs` folder
- **Email**: support@smartpendant.com

## License

[Your License Here]

---

**Version**: 1.0.0  
**Last Updated**: October 10, 2025
