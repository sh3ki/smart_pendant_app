class Device {
  final String id;
  final String name;
  final bool online;
  final String lastSeen;
  final int battery;

  Device({required this.id, required this.name, required this.online, required this.lastSeen, required this.battery});
}
