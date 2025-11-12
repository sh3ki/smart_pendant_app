import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';

// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings());

  void updateImageQuality(String quality) {
    state = state.copyWith(imageQuality: quality);
    // In real app, persist to shared_preferences or secure storage
  }

  void updateTelemetryFrequency(int frequency) {
    state = state.copyWith(telemetryFrequency: frequency);
  }

  void updateSosNotifications(bool enabled) {
    state = state.copyWith(sosNotifications: enabled);
  }

  void updateLowBatteryNotifications(bool enabled) {
    state = state.copyWith(lowBatteryNotifications: enabled);
  }

  void updateOfflineNotifications(bool enabled) {
    state = state.copyWith(offlineNotifications: enabled);
  }
}
