import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Request location permission (required for Android 13+)
  Future<bool> requestLocationPermission() async {
    var status = await Permission.location.request();
    
    if (status.isGranted) {
      print('✅ Location permission granted');
      return true;
    } else if (status.isDenied) {
      print('❌ Location permission denied');
      return false;
    } else if (status.isPermanentlyDenied) {
      print('❌ Location permission permanently denied - open settings');
      await openAppSettings();
      return false;
    }
    
    return false;
  }
}
