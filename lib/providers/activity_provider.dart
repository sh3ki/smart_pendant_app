import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import 'telemetry_provider.dart';

// Activity history provider
final activityHistoryProvider = StateNotifierProvider<ActivityHistoryNotifier, List<Telemetry>>((ref) {
  return ActivityHistoryNotifier(ref);
});

class ActivityHistoryNotifier extends StateNotifier<List<Telemetry>> {
  final Ref _ref;
  
  ActivityHistoryNotifier(this._ref) : super([]) {
    // Listen to telemetry updates
    _ref.listen<Telemetry?>(telemetryProvider, (previous, next) {
      if (next != null) {
        _addActivity(next);
      }
    });
  }

  void _addActivity(Telemetry telemetry) {
    final updated = [...state, telemetry];
    // Keep last 100 activity points (about 8 minutes at 5s intervals)
    if (updated.length > 100) {
      updated.removeAt(0);
    }
    state = updated;
  }
}
