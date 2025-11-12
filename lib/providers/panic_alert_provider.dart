import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/panic_alert_service.dart';
import '../services/websocket_service.dart';
import '../services/local_storage_service.dart';
import '../models/app_models.dart';
import '../models/stored_models.dart';
import 'sos_provider.dart';

// Service provider
final panicAlertServiceProvider = Provider<PanicAlertService>((ref) {
  return PanicAlertService();
});

// WebSocket service provider
final websocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

// State class
class PanicAlertState {
  final bool isAlerting;
  final Map<String, dynamic>? currentAlert;
  final List<Map<String, dynamic>> alertHistory;

  const PanicAlertState({
    this.isAlerting = false,
    this.currentAlert,
    this.alertHistory = const [],
  });

  PanicAlertState copyWith({
    bool? isAlerting,
    Map<String, dynamic>? currentAlert,
    List<Map<String, dynamic>>? alertHistory,
  }) {
    return PanicAlertState(
      isAlerting: isAlerting ?? this.isAlerting,
      currentAlert: currentAlert ?? this.currentAlert,
      alertHistory: alertHistory ?? this.alertHistory,
    );
  }
}

// Notifier
class PanicAlertNotifier extends StateNotifier<PanicAlertState> {
  final PanicAlertService _panicService;
  final WebSocketService _websocketService;
  final Ref _ref;
  StreamSubscription? _alertSubscription;
  OverlayEntry? _currentOverlay;

  PanicAlertNotifier(this._panicService, this._websocketService, this._ref)
      : super(const PanicAlertState()) {
    _init();
  }

  void _init() async {
    // Set up callbacks
    _panicService.onAlertStarted = _onAlertStarted;
    _panicService.onAlertStopped = _onAlertStopped;

    // Connect to WebSocket (using pendant-1 as default device ID)
    try {
      await _websocketService.connect('pendant-1');
      print('✅ WebSocket connected for panic alerts');
    } catch (e) {
      print('❌ Failed to connect WebSocket: $e');
    }

    // Listen to WebSocket alert stream
    _alertSubscription = _websocketService.alertStream.listen((alertData) {
      print('🚨 Panic alert received from WebSocket: $alertData');
      handlePanicAlert(alertData);
    });
  }

  void _onAlertStarted(Map<String, dynamic> alertData) {
    state = state.copyWith(
      isAlerting: true,
      currentAlert: alertData,
    );
  }

  void _onAlertStopped() {
    // Add to history
    if (state.currentAlert != null) {
      final history = List<Map<String, dynamic>>.from(state.alertHistory);
      history.insert(0, state.currentAlert!);
      state = state.copyWith(
        isAlerting: false,
        currentAlert: null,
        alertHistory: history,
      );
    } else {
      state = state.copyWith(isAlerting: false, currentAlert: null);
    }

    // Remove overlay
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Handle incoming panic alert
  Future<void> handlePanicAlert(Map<String, dynamic> alertData) async {
    if (state.isAlerting) {
      print('⚠️ Panic alert already in progress, ignoring new alert');
      return;
    }

    print('🚨 Triggering panic alert UI');

    // Replace Arduino timestamp with mobile's current UTC time (for accuracy)
    // This ensures the timestamp is always correct regardless of Arduino's NTP sync status
    alertData['timestamp'] = DateTime.now().toUtc().toIso8601String();
    print('📅 Using mobile timestamp: ${alertData['timestamp']}');

    // Save to SOS history immediately
    _saveToSosHistory(alertData);

    // Start the panic alert service (beep + vibration for 10 seconds)
    await _panicService.startPanicAlert(alertData);
  }

  /// Save panic alert to SOS history
  void _saveToSosHistory(Map<String, dynamic> alertData) {
    try {
      final location = alertData['location'] as Map<String, dynamic>?;
      
      final sosAlert = SosAlert(
        id: alertData['id'] as String? ?? 'alert-${DateTime.now().millisecondsSinceEpoch}',
        deviceId: alertData['deviceId'] as String? ?? 'pendant-1',
        timestamp: alertData['timestamp'] as String? ?? DateTime.now().toUtc().toIso8601String(),
        lat: location?['latitude'] as double? ?? location?['lat'] as double? ?? 0.0,
        lon: location?['longitude'] as double? ?? location?['lon'] as double? ?? 0.0,
        imageUrl: null, // Can be updated later if camera captures image
        handled: false,
      );

      // Add to SOS provider
      _ref.read(sosAlertsProvider.notifier).addAlert(sosAlert);
      
      // Save to local storage for persistence
      final storedAlert = StoredPanicAlert.fromMap(alertData);
      LocalStorageService().savePanicAlert(storedAlert);
      
      print('✅ Panic alert saved to SOS history and local storage');
    } catch (e) {
      print('❌ Failed to save panic alert to SOS history: $e');
    }
  }

  /// Show overlay on screen (called from UI)
  void showOverlay(BuildContext context, Map<String, dynamic> alertData) {
    if (_currentOverlay != null) return;

    _currentOverlay = _panicService.createAlertOverlay(context, alertData);
    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Manually dismiss alert
  void dismissAlert() {
    _panicService.stopPanicAlert();
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _panicService.dispose();
    _currentOverlay?.remove();
    super.dispose();
  }
}

// Provider
final panicAlertProvider =
    StateNotifierProvider<PanicAlertNotifier, PanicAlertState>((ref) {
  final panicService = ref.watch(panicAlertServiceProvider);
  final websocketService = ref.watch(websocketServiceProvider);
  return PanicAlertNotifier(panicService, websocketService, ref);
});
