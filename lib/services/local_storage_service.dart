import 'package:hive_flutter/hive_flutter.dart';
import '../models/stored_models.dart';

class LocalStorageService {
  // Box names
  static const String _telemetryBox = 'telemetry_box';
  static const String _panicAlertBox = 'panic_alert_box';
  static const String _activityBox = 'activity_box';
  static const String _deviceStateBox = 'device_state_box';

  // Hive boxes
  late Box<StoredTelemetry> _telemetryStorage;
  late Box<StoredPanicAlert> _panicAlertStorage;
  late Box<StoredActivityRecord> _activityStorage;
  late Box<dynamic> _deviceStateStorage;

  // Singleton instance
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // Initialize Hive and open boxes
  Future<void> initialize() async {
    print('📦 Initializing Local Storage...');
    
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(StoredTelemetryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StoredPanicAlertAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(StoredActivityRecordAdapter());
    }

    // Open boxes
    _telemetryStorage = await Hive.openBox<StoredTelemetry>(_telemetryBox);
    _panicAlertStorage = await Hive.openBox<StoredPanicAlert>(_panicAlertBox);
    _activityStorage = await Hive.openBox<StoredActivityRecord>(_activityBox);
    _deviceStateStorage = await Hive.openBox(_deviceStateBox);

    print('✅ Local Storage initialized');
    print('   📊 Telemetry records: ${_telemetryStorage.length}');
    print('   🚨 Panic alerts: ${_panicAlertStorage.length}');
    print('   🏃 Activity records: ${_activityStorage.length}');
  }

  // ========================================
  // 📊 TELEMETRY STORAGE
  // ========================================
  
  Future<void> saveTelemetry(StoredTelemetry telemetry) async {
    await _telemetryStorage.put(telemetry.timestamp, telemetry);
    print('💾 Telemetry saved: ${telemetry.motionState} @ ${telemetry.timestamp}');
    
    // Auto-cleanup: Keep only last 1000 records
    if (_telemetryStorage.length > 1000) {
      final oldestKey = _telemetryStorage.keys.first;
      await _telemetryStorage.delete(oldestKey);
    }
  }

  StoredTelemetry? getLatestTelemetry() {
    if (_telemetryStorage.isEmpty) return null;
    return _telemetryStorage.values.last;
  }

  List<StoredTelemetry> getAllTelemetry() {
    return _telemetryStorage.values.toList();
  }

  List<StoredTelemetry> getTelemetryByDateRange(DateTime start, DateTime end) {
    return _telemetryStorage.values.where((telemetry) {
      final timestamp = DateTime.parse(telemetry.timestamp);
      return timestamp.isAfter(start) && timestamp.isBefore(end);
    }).toList();
  }

  Future<void> clearTelemetry() async {
    await _telemetryStorage.clear();
    print('🗑️ Telemetry cleared');
  }

  // ========================================
  // 🚨 PANIC ALERT STORAGE
  // ========================================
  
  Future<void> savePanicAlert(StoredPanicAlert alert) async {
    await _panicAlertStorage.put(alert.id, alert);
    print('💾 Panic alert saved: ${alert.id} @ ${alert.timestamp}');
  }

  List<StoredPanicAlert> getAllPanicAlerts() {
    return _panicAlertStorage.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
  }

  List<StoredPanicAlert> getUnhandledPanicAlerts() {
    return _panicAlertStorage.values
        .where((alert) => !alert.handled)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> markAlertAsHandled(String alertId) async {
    final alert = _panicAlertStorage.get(alertId);
    if (alert != null) {
      final updatedAlert = StoredPanicAlert(
        id: alert.id,
        deviceId: alert.deviceId,
        timestamp: alert.timestamp,
        lat: alert.lat,
        lon: alert.lon,
        handled: true,
        handledAt: DateTime.now().toIso8601String(),
      );
      await _panicAlertStorage.put(alertId, updatedAlert);
      print('✅ Alert marked as handled: $alertId');
    }
  }

  Future<void> clearPanicAlerts() async {
    await _panicAlertStorage.clear();
    print('🗑️ Panic alerts cleared');
  }

  // ========================================
  // 🏃 ACTIVITY STORAGE
  // ========================================
  
  Future<void> saveActivityRecord(StoredActivityRecord activity) async {
    await _activityStorage.put(activity.id, activity);
    print('💾 Activity saved: ${activity.activityType} @ ${activity.timestamp}');
    
    // Auto-cleanup: Keep only last 5000 records
    if (_activityStorage.length > 5000) {
      final oldestKey = _activityStorage.keys.first;
      await _activityStorage.delete(oldestKey);
    }
  }

  List<StoredActivityRecord> getAllActivity() {
    return _activityStorage.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
  }

  List<StoredActivityRecord> getActivityByType(String type) {
    return _activityStorage.values
        .where((activity) => activity.activityType.toLowerCase() == type.toLowerCase())
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<StoredActivityRecord> getActivityByDateRange(DateTime start, DateTime end) {
    return _activityStorage.values.where((activity) {
      final timestamp = DateTime.parse(activity.timestamp);
      return timestamp.isAfter(start) && timestamp.isBefore(end);
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> clearActivity() async {
    await _activityStorage.clear();
    print('🗑️ Activity records cleared');
  }

  // ========================================
  // 📱 DEVICE STATE STORAGE
  // ========================================
  
  Future<void> saveDeviceState(Map<String, dynamic> state) async {
    await _deviceStateStorage.put('current_state', state);
    print('💾 Device state saved');
  }

  Map<String, dynamic>? getDeviceState() {
    return _deviceStateStorage.get('current_state');
  }

  Future<void> updateLastSeen(String timestamp) async {
    final state = getDeviceState() ?? {};
    state['lastSeen'] = timestamp;
    state['online'] = true;
    await saveDeviceState(state);
  }

  Future<void> updateBattery(int batteryPercent) async {
    final state = getDeviceState() ?? {};
    state['battery'] = batteryPercent;
    await saveDeviceState(state);
  }

  // ========================================
  // 🗑️ CLEAR ALL DATA
  // ========================================
  
  Future<void> clearAllData() async {
    await clearTelemetry();
    await clearPanicAlerts();
    await clearActivity();
    await _deviceStateStorage.clear();
    print('🗑️ All local data cleared');
  }

  // ========================================
  // 📊 STATISTICS
  // ========================================
  
  Map<String, int> getStorageStats() {
    return {
      'telemetry': _telemetryStorage.length,
      'panicAlerts': _panicAlertStorage.length,
      'activity': _activityStorage.length,
    };
  }

  void printStats() {
    final stats = getStorageStats();
    print('📊 Storage Statistics:');
    print('   📡 Telemetry: ${stats['telemetry']} records');
    print('   🚨 Panic Alerts: ${stats['panicAlerts']} records');
    print('   🏃 Activity: ${stats['activity']} records');
  }
}
