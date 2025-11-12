import 'package:hive/hive.dart';

part 'stored_models.g.dart';

// ========================================
// 📊 STORED TELEMETRY DATA
// ========================================
@HiveType(typeId: 0)
class StoredTelemetry extends HiveObject {
  @HiveField(0)
  final String deviceId;

  @HiveField(1)
  final String timestamp;

  @HiveField(2)
  final double lat;

  @HiveField(3)
  final double lon;

  @HiveField(4)
  final double accuracyMeters;

  @HiveField(5)
  final double speed;

  @HiveField(6)
  final double? alt;

  @HiveField(7)
  final int batteryPercent;

  @HiveField(8)
  final int? signalDbm;

  @HiveField(9)
  final String motionState;

  @HiveField(10)
  final String? firmwareVersion;

  @HiveField(11)
  final double accelX;

  @HiveField(12)
  final double accelY;

  @HiveField(13)
  final double accelZ;

  StoredTelemetry({
    required this.deviceId,
    required this.timestamp,
    required this.lat,
    required this.lon,
    required this.accuracyMeters,
    required this.speed,
    this.alt,
    required this.batteryPercent,
    this.signalDbm,
    required this.motionState,
    this.firmwareVersion,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
  });

  factory StoredTelemetry.fromMap(Map<String, dynamic> json) {
    return StoredTelemetry(
      deviceId: json['deviceId'] as String? ?? 'pendant-1',
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      alt: (json['alt'] as num?)?.toDouble(),
      batteryPercent: (json['batteryPercent'] as num?)?.toInt() ?? 0,
      signalDbm: (json['signalDbm'] as num?)?.toInt(),
      motionState: (json['motionState'] as String?)?.toLowerCase() ?? 'rest',
      firmwareVersion: json['firmwareVersion'] as String?,
      accelX: (json['accelerometer']?['x'] as num?)?.toDouble() ?? 0.0,
      accelY: (json['accelerometer']?['y'] as num?)?.toDouble() ?? 0.0,
      accelZ: (json['accelerometer']?['z'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'timestamp': timestamp,
      'lat': lat,
      'lon': lon,
      'accuracyMeters': accuracyMeters,
      'speed': speed,
      'alt': alt,
      'batteryPercent': batteryPercent,
      'signalDbm': signalDbm,
      'motionState': motionState,
      'firmwareVersion': firmwareVersion,
      'accelX': accelX,
      'accelY': accelY,
      'accelZ': accelZ,
    };
  }
}

// ========================================
// 🚨 STORED PANIC ALERT
// ========================================
@HiveType(typeId: 1)
class StoredPanicAlert extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String deviceId;

  @HiveField(2)
  final String timestamp;

  @HiveField(3)
  final double lat;

  @HiveField(4)
  final double lon;

  @HiveField(5)
  final bool handled;

  @HiveField(6)
  final String? handledAt;

  StoredPanicAlert({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.lat,
    required this.lon,
    required this.handled,
    this.handledAt,
  });

  factory StoredPanicAlert.fromMap(Map<String, dynamic> json) {
    return StoredPanicAlert(
      id: json['id'] as String? ?? 'alert-${DateTime.now().millisecondsSinceEpoch}',
      deviceId: json['deviceId'] as String? ?? 'pendant-1',
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      lat: (json['location']?['latitude'] as num?)?.toDouble() ?? 
           (json['location']?['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['location']?['longitude'] as num?)?.toDouble() ?? 
           (json['location']?['lng'] as num?)?.toDouble() ?? 0.0,
      handled: json['handled'] as bool? ?? false,
      handledAt: json['handledAt'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'timestamp': timestamp,
      'lat': lat,
      'lon': lon,
      'handled': handled,
      'handledAt': handledAt,
    };
  }
}

// ========================================
// 🏃 STORED ACTIVITY RECORD
// ========================================
@HiveType(typeId: 2)
class StoredActivityRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String timestamp;

  @HiveField(2)
  final String activityType;

  @HiveField(3)
  final double speed;

  @HiveField(4)
  final int steps;

  @HiveField(5)
  final int calories;

  @HiveField(6)
  final double accelX;

  @HiveField(7)
  final double accelY;

  @HiveField(8)
  final double accelZ;

  StoredActivityRecord({
    required this.id,
    required this.timestamp,
    required this.activityType,
    required this.speed,
    required this.steps,
    required this.calories,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
  });

  factory StoredActivityRecord.fromTelemetry(StoredTelemetry telemetry) {
    return StoredActivityRecord(
      id: 'activity-${telemetry.timestamp}',
      timestamp: telemetry.timestamp,
      activityType: telemetry.motionState,
      speed: telemetry.speed,
      steps: 0, // Will be calculated
      calories: 0, // Will be calculated
      accelX: telemetry.accelX,
      accelY: telemetry.accelY,
      accelZ: telemetry.accelZ,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'activityType': activityType,
      'speed': speed,
      'steps': steps,
      'calories': calories,
      'accelX': accelX,
      'accelY': accelY,
      'accelZ': accelZ,
    };
  }
}
