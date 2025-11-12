import '../models/device.dart';

class MockDeviceService {
  List<Device> getDevices() {
    return [
      Device(id: 'pendant-1', name: 'Liam\'s Pendant', online: true, lastSeen: '2025-10-10T12:34:56Z', battery: 86),
      Device(id: 'pendant-2', name: 'Ava\'s Pendant', online: false, lastSeen: '2025-10-09T09:12:34Z', battery: 24),
    ];
  }
}
