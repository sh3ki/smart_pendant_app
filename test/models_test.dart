import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pendant_app/models/app_models.dart';

void main() {
  group('Telemetry Model Tests', () {
    test('Telemetry fromJson creates valid object', () {
      final json = {
        'deviceId': 'pendant-001',
        'timestamp': '2025-10-10T12:00:00Z',
        'lat': 37.7749,
        'lon': -122.4194,
        'accuracyMeters': 5.0,
        'speed': 1.5,
        'batteryPercent': 75,
        'motionState': 'walk',
      };

      final telemetry = Telemetry.fromJson(json);

      expect(telemetry.deviceId, 'pendant-001');
      expect(telemetry.lat, 37.7749);
      expect(telemetry.lon, -122.4194);
      expect(telemetry.motionState, 'walk');
      expect(telemetry.batteryPercent, 75);
    });

    test('Telemetry toJson produces correct map', () {
      final telemetry = Telemetry(
        deviceId: 'pendant-001',
        timestamp: '2025-10-10T12:00:00Z',
        lat: 37.7749,
        lon: -122.4194,
        accuracyMeters: 5.0,
        speed: 1.5,
        batteryPercent: 75,
        motionState: 'walk',
      );

      final json = telemetry.toJson();

      expect(json['deviceId'], 'pendant-001');
      expect(json['lat'], 37.7749);
      expect(json['motionState'], 'walk');
    });
  });

  group('AppSettings Tests', () {
    test('AppSettings default values', () {
      final settings = AppSettings();

      expect(settings.imageQuality, 'high');
      expect(settings.telemetryFrequency, 15);
      expect(settings.sosNotifications, true);
    });

    test('AppSettings copyWith updates correctly', () {
      final settings = AppSettings();
      final updated = settings.copyWith(imageQuality: 'low', telemetryFrequency: 30);

      expect(updated.imageQuality, 'low');
      expect(updated.telemetryFrequency, 30);
      expect(updated.sosNotifications, true); // unchanged
    });
  });
}
