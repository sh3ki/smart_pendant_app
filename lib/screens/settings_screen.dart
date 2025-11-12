import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Device Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Image Quality'),
            subtitle: Text(settings.imageQuality),
            trailing: DropdownButton<String>(
              value: settings.imageQuality,
              items: const [
                DropdownMenuItem(value: 'high', child: Text('High (320x240)')),
                DropdownMenuItem(value: 'medium', child: Text('Medium (240x180)')),
                DropdownMenuItem(value: 'low', child: Text('Low (160x120)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateImageQuality(value);
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Telemetry Frequency'),
            subtitle: Text('${settings.telemetryFrequency} seconds'),
            trailing: DropdownButton<int>(
              value: settings.telemetryFrequency,
              items: const [
                DropdownMenuItem(value: 5, child: Text('5s')),
                DropdownMenuItem(value: 10, child: Text('10s')),
                DropdownMenuItem(value: 15, child: Text('15s')),
                DropdownMenuItem(value: 30, child: Text('30s')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateTelemetryFrequency(value);
                }
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('SOS Alerts'),
            subtitle: const Text('Receive push notifications for SOS events'),
            value: settings.sosNotifications,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateSosNotifications(value);
            },
          ),
          SwitchListTile(
            title: const Text('Low Battery Alerts'),
            subtitle: const Text('Notify when device battery is low'),
            value: settings.lowBatteryNotifications,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateLowBatteryNotifications(value);
            },
          ),
          SwitchListTile(
            title: const Text('Offline Alerts'),
            subtitle: const Text('Notify when device goes offline'),
            value: settings.offlineNotifications,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateOfflineNotifications(value);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0+1'),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open privacy policy (TODO: url_launcher)')),
              );
            },
          ),
        ],
      ),
    );
  }
}
