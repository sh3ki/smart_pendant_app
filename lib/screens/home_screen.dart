import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/telemetry_provider.dart';
import '../providers/panic_alert_provider.dart';
import '../utils/time_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize panic alert provider after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize the provider (this triggers WebSocket connection)
      ref.read(panicAlertProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final device = ref.watch(deviceStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Pendant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(telemetryProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Device status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          device.online ? Icons.check_circle : Icons.offline_bolt,
                          color: device.online ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          device.online ? 'Online' : 'Offline',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Icon(Icons.battery_full, color: device.batteryPercent > 20 ? Colors.green : Colors.red),
                        const SizedBox(width: 4),
                        Text('${device.batteryPercent}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Date/Time: ${TimeUtils.formatTimestamp(device.lastSeen, format: 'MMM dd, yyyy h:mm:ss a')}', style: Theme.of(context).textTheme.bodySmall),
                    if (device.signalDbm != null)
                      Text('Signal: ${device.signalDbm} dBm', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _QuickActionCard(
                  icon: Icons.map,
                  label: 'Map',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/map'),
                ),
                _QuickActionCard(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.purple,
                  onTap: () => Navigator.pushNamed(context, '/camera'),
                ),
                _QuickActionCard(
                  icon: Icons.mic,
                  label: 'Speak',
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, '/audio'),
                ),
                _QuickActionCard(
                  icon: Icons.directions_run,
                  label: 'Activity',
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, '/activity'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current location card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Location', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${telemetry?.lat.toStringAsFixed(6)}, ${telemetry?.lon.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Accuracy: ${telemetry?.accuracyMeters.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodySmall),
                    Text('Speed: ${telemetry?.displaySpeed.toStringAsFixed(1)} m/s', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Activity card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Activity', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(_getActivityIcon(telemetry?.motionState ?? 'rest'), size: 32, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          telemetry?.motionState.toUpperCase() ?? 'UNKNOWN',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SOS button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pushNamed(context, '/sos'),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, size: 28),
                    SizedBox(width: 12),
                    Text('SOS Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(String state) {
    switch (state.toLowerCase()) {
      case 'run':
        return Icons.directions_run;
      case 'walk':
        return Icons.directions_walk;
      default:
        return Icons.hotel;
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
