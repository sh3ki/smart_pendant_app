import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';

// SOS alerts provider
final sosAlertsProvider = StateNotifierProvider<SosAlertsNotifier, List<SosAlert>>((ref) {
  return SosAlertsNotifier();
});

class SosAlertsNotifier extends StateNotifier<List<SosAlert>> {
  SosAlertsNotifier() : super([]);
  
  // No mock data - alerts are added when panic button is pressed

  void addAlert(SosAlert alert) {
    state = [alert, ...state];
  }

  void markAsHandled(String alertId) {
    state = state.map((alert) {
      if (alert.id == alertId) {
        return alert.copyWith(handled: true);
      }
      return alert;
    }).toList();
  }

  // Simulate receiving a new SOS alert (for testing)
  void simulateSosAlert() {
    final newAlert = SosAlert(
      id: 'sos-${DateTime.now().millisecondsSinceEpoch}',
      deviceId: 'pendant-001',
      timestamp: DateTime.now().toIso8601String(),
      lat: 37.7749,
      lon: -122.4194,
      imageUrl: 'https://picsum.photos/320/240',
    );
    addAlert(newAlert);
  }
}
