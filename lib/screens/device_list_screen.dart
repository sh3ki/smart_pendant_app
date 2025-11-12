import 'package:flutter/material.dart';
import '../services/mock_device_service.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final _service = MockDeviceService();

  @override
  Widget build(BuildContext context) {
    final devices = _service.getDevices();
    return Scaffold(
      appBar: AppBar(title: const Text('My Devices')),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final d = devices[index];
          return ListTile(
            leading: CircleAvatar(child: Text(d.name[0])),
            title: Text(d.name),
            subtitle: Text('Last seen: ${d.lastSeen} • Battery: ${d.battery}%'),
            trailing: Icon(d.online ? Icons.check_circle : Icons.offline_bolt, color: d.online ? Colors.green : Colors.grey),
            onTap: () => Navigator.pushNamed(context, '/device', arguments: d),
          );
        },
      ),
    );
  }
}
