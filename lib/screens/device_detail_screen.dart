import 'package:flutter/material.dart';
import '../models/device.dart';

class DeviceDetailScreen extends StatelessWidget {
  const DeviceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final device = ModalRoute.of(context)!.settings.arguments as Device;
    return Scaffold(
      appBar: AppBar(title: Text(device.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${device.online ? 'Online' : 'Offline'}'),
            const SizedBox(height: 8),
            Text('Last seen: ${device.lastSeen}'),
            const SizedBox(height: 8),
            Text('Battery: ${device.battery}%'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/camera', arguments: device),
                  child: const Text('Camera'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/audio', arguments: device),
                  child: const Text('Listen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
