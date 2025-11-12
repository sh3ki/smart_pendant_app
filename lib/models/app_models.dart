class Telemetry {
  final String deviceId;
  final String timestamp;
  final double lat;
  final double lon;
  final double accuracyMeters;
  final double speed;
  final double? alt;
  final int batteryPercent;
  final int? signalDbm;
  final String motionState;
  final String? firmwareVersion;

  Telemetry({
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
  });

  /// Get display speed with filtering:
  /// - If speed <= 0.3 m/s, return 0.0 (resting/stationary)
  /// - Otherwise return actual speed
  double get displaySpeed {
    return speed <= 0.3 ? 0.0 : speed;
  }

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      deviceId: json['deviceId'] as String,
      timestamp: json['timestamp'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      alt: json['alt'] != null ? (json['alt'] as num).toDouble() : null,
      batteryPercent: json['batteryPercent'] as int,
      signalDbm: json['signalDbm'] as int?,
      motionState: json['motionState'] as String,
      firmwareVersion: json['firmwareVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
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
    };
  }
}

class DeviceState {
  final String deviceId;
  final String name;
  final bool online;
  final String lastSeen;
  final int batteryPercent;
  final int? signalDbm;

  DeviceState({
    required this.deviceId,
    required this.name,
    required this.online,
    required this.lastSeen,
    required this.batteryPercent,
    this.signalDbm,
  });
}

class CameraState {
  final String? imageUrl;
  final String? timestamp;
  final bool isLoading;
  final int? frameNumber;

  CameraState({
    this.imageUrl,
    this.timestamp,
    this.isLoading = false,
    this.frameNumber,
  });

  CameraState copyWith({
    String? imageUrl,
    String? timestamp,
    bool? isLoading,
    int? frameNumber,
  }) {
    return CameraState(
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      frameNumber: frameNumber ?? this.frameNumber,
    );
  }
}

class AudioState {
  final bool isListening;
  final bool isBuffering;
  final String? error;

  AudioState({
    this.isListening = false,
    this.isBuffering = false,
    this.error,
  });

  AudioState copyWith({
    bool? isListening,
    bool? isBuffering,
    String? error,
  }) {
    return AudioState(
      isListening: isListening ?? this.isListening,
      isBuffering: isBuffering ?? this.isBuffering,
      error: error,
    );
  }
}

class SosAlert {
  final String id;
  final String deviceId;
  final String timestamp;
  final double lat;
  final double lon;
  final String? imageUrl;
  final bool handled;

  SosAlert({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.lat,
    required this.lon,
    this.imageUrl,
    this.handled = false,
  });

  SosAlert copyWith({bool? handled}) {
    return SosAlert(
      id: id,
      deviceId: deviceId,
      timestamp: timestamp,
      lat: lat,
      lon: lon,
      imageUrl: imageUrl,
      handled: handled ?? this.handled,
    );
  }
}

class AppSettings {
  final String imageQuality;
  final int telemetryFrequency;
  final bool sosNotifications;
  final bool lowBatteryNotifications;
  final bool offlineNotifications;

  AppSettings({
    this.imageQuality = 'high',
    this.telemetryFrequency = 15,
    this.sosNotifications = true,
    this.lowBatteryNotifications = true,
    this.offlineNotifications = true,
  });

  AppSettings copyWith({
    String? imageQuality,
    int? telemetryFrequency,
    bool? sosNotifications,
    bool? lowBatteryNotifications,
    bool? offlineNotifications,
  }) {
    return AppSettings(
      imageQuality: imageQuality ?? this.imageQuality,
      telemetryFrequency: telemetryFrequency ?? this.telemetryFrequency,
      sosNotifications: sosNotifications ?? this.sosNotifications,
      lowBatteryNotifications: lowBatteryNotifications ?? this.lowBatteryNotifications,
      offlineNotifications: offlineNotifications ?? this.offlineNotifications,
    );
  }
}
