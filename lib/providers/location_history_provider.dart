import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import 'telemetry_provider.dart';

// Location history provider (keeps last 50 telemetry points)
final locationHistoryProvider = StateNotifierProvider<LocationHistoryNotifier, List<Telemetry>>((ref) {
  return LocationHistoryNotifier(ref);
});

class LocationHistoryNotifier extends StateNotifier<List<Telemetry>> {
  final Ref _ref;
  
  LocationHistoryNotifier(this._ref) : super([]) {
    // Listen to telemetry updates
    _ref.listen<Telemetry?>(telemetryProvider, (previous, next) {
      if (next != null) {
        _addTelemetry(next);
      }
    });
  }

  void _addTelemetry(Telemetry telemetry) {
    final updated = [...state, telemetry];
    // Keep only last 50 points
    if (updated.length > 50) {
      updated.removeAt(0);
    }
    state = updated;
  }
}
