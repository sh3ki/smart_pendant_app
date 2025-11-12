import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../models/stored_models.dart';
import '../services/websocket_service.dart';
import '../services/local_storage_service.dart';
import 'panic_alert_provider.dart';  // Import to reuse websocketServiceProvider

// Real telemetry provider using WebSocket + Local Storage
final telemetryProvider = StateNotifierProvider<TelemetryNotifier, Telemetry?>((ref) {
  final websocketService = ref.watch(websocketServiceProvider);
  final localStorage = LocalStorageService();
  return TelemetryNotifier(websocketService, localStorage);
});

class TelemetryNotifier extends StateNotifier<Telemetry?> {
  final WebSocketService _websocketService;
  final LocalStorageService _localStorage;
  StreamSubscription<Map<String, dynamic>>? _telemetrySubscription;

  TelemetryNotifier(this._websocketService, this._localStorage) : super(null) {
    _initializeWebSocket();
    _loadLastTelemetry();
  }

  // Load last saved telemetry on startup
  Future<void> _loadLastTelemetry() async {
    final lastTelemetry = _localStorage.getLatestTelemetry();
    if (lastTelemetry != null) {
      state = Telemetry(
        deviceId: lastTelemetry.deviceId,
        timestamp: lastTelemetry.timestamp,
        lat: lastTelemetry.lat,
        lon: lastTelemetry.lon,
        accuracyMeters: lastTelemetry.accuracyMeters,
        speed: lastTelemetry.speed,
        alt: lastTelemetry.alt,
        batteryPercent: lastTelemetry.batteryPercent,
        signalDbm: lastTelemetry.signalDbm,
        motionState: lastTelemetry.motionState,
        firmwareVersion: lastTelemetry.firmwareVersion,
      );
      print('📱 Loaded last telemetry from storage: ${lastTelemetry.motionState}');
    }
  }

  Future<void> _initializeWebSocket() async {
    try {
      // Connect to WebSocket (using pendant-1 as default device ID)
      await _websocketService.connect('pendant-1');
      print('✅ WebSocket connected for telemetry');
    } catch (e) {
      print('❌ Failed to connect WebSocket for telemetry: $e');
    }

    // Listen to WebSocket telemetry stream
    _telemetrySubscription = _websocketService.telemetryStream.listen((telemetryData) {
      print('📡 Telemetry received from WebSocket: $telemetryData');
      
      try {
        // Parse telemetry data from backend
        state = Telemetry(
          deviceId: telemetryData['deviceId'] as String? ?? 'pendant-1',
          timestamp: telemetryData['timestamp'] as String? ?? DateTime.now().toIso8601String(),
          lat: (telemetryData['lat'] as num?)?.toDouble() ?? 37.7749,
          lon: (telemetryData['lon'] as num?)?.toDouble() ?? -122.4194,
          accuracyMeters: (telemetryData['accuracyMeters'] as num?)?.toDouble() ?? 13.1,
          speed: (telemetryData['speed'] as num?)?.toDouble() ?? 0.0,
          alt: (telemetryData['alt'] as num?)?.toDouble(),
          batteryPercent: (telemetryData['batteryPercent'] as num?)?.toInt() ?? 75,
          signalDbm: (telemetryData['signalDbm'] as num?)?.toInt(),
          motionState: (telemetryData['motionState'] as String?)?.toLowerCase() ?? 'rest',
          firmwareVersion: telemetryData['firmwareVersion'] as String?,
        );
        
        print('✅ Telemetry state updated: ${state?.motionState} @ ${state?.speed} m/s');
        
        // Save to local storage for persistence
        final storedTelemetry = StoredTelemetry.fromMap(telemetryData);
        _localStorage.saveTelemetry(storedTelemetry);
        
        // Also save as activity record
        final activityRecord = StoredActivityRecord.fromTelemetry(storedTelemetry);
        _localStorage.saveActivityRecord(activityRecord);
        
      } catch (e) {
        print('❌ Error parsing telemetry data: $e');
      }
    });
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    super.dispose();
  }
}

// Device state provider
final deviceStateProvider = Provider<DeviceState>((ref) {
  final telemetry = ref.watch(telemetryProvider);
  
  return DeviceState(
    deviceId: 'pendant-001',
    name: "Child's Pendant",
    online: telemetry != null,
    lastSeen: telemetry?.timestamp ?? DateTime.now().toIso8601String(),
    batteryPercent: telemetry?.batteryPercent ?? 0,
    signalDbm: telemetry?.signalDbm,
  );
});
