import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/sos_provider.dart';
import '../utils/time_utils.dart';

class SosScreen extends ConsumerWidget {
  const SosScreen({super.key});

  String _formatDateTime(String timestamp) {
    // Use the same format as home screen: MMM dd, yyyy h:mm:ss a
    return TimeUtils.formatTimestamp(timestamp, format: 'MMM dd, yyyy h:mm:ss a');
  }

  String _formatDateOnly(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMMM d, yyyy').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  String _formatTimeOnly(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('h:mm:ss a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosAlerts = ref.watch(sosAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Alerts'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: sosAlerts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green[300]),
                  const SizedBox(height: 24),
                  Text(
                    'No SOS Alerts',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All clear! No emergency alerts.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sosAlerts.length,
              itemBuilder: (context, index) {
                final alert = sosAlerts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: alert.handled ? 1 : 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: alert.handled 
                          ? Colors.grey[300] 
                          : Colors.red[100],
                      child: Icon(
                        alert.handled ? Icons.check_circle : Icons.warning_rounded,
                        color: alert.handled ? Colors.grey[600] : Colors.red,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      'Panic Button Pressed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: alert.handled ? Colors.grey[600] : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _formatDateTime(alert.timestamp),
                                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${alert.lat.toStringAsFixed(6)}, ${alert.lon.toStringAsFixed(6)}',
                                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                        if (alert.handled)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'Handled',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: !alert.handled
                        ? PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                            onSelected: (value) {
                              if (value == 'mark') {
                                ref.read(sosAlertsProvider.notifier).markAsHandled(alert.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Alert marked as handled'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else if (value == 'navigate') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening navigation...')),
                                );
                              } else if (value == 'call') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Calling emergency contact...')),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'navigate',
                                child: Row(
                                  children: [
                                    Icon(Icons.navigation, size: 20),
                                    SizedBox(width: 12),
                                    Text('Navigate to Location'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'call',
                                child: Row(
                                  children: [
                                    Icon(Icons.phone, size: 20),
                                    SizedBox(width: 12),
                                    Text('Call Emergency'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'mark',
                                child: Row(
                                  children: [
                                    Icon(Icons.check, size: 20, color: Colors.green),
                                    SizedBox(width: 12),
                                    Text('Mark as Handled'),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : null,
                    onTap: () {
                      // Show detailed alert dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: alert.handled ? Colors.grey : Colors.red,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('SOS Alert Details'),
                              ),
                            ],
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow(
                                  icon: Icons.event,
                                  label: 'Date',
                                  value: _formatDateOnly(alert.timestamp),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: Icons.access_time,
                                  label: 'Time',
                                  value: _formatTimeOnly(alert.timestamp),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: Icons.location_on,
                                  label: 'Latitude',
                                  value: alert.lat.toStringAsFixed(6),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: Icons.location_on,
                                  label: 'Longitude',
                                  value: alert.lon.toStringAsFixed(6),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: Icons.info,
                                  label: 'Device ID',
                                  value: alert.deviceId,
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: alert.handled ? Icons.check_circle : Icons.priority_high,
                                  label: 'Status',
                                  value: alert.handled ? 'Handled' : 'Active',
                                  valueColor: alert.handled ? Colors.green : Colors.red,
                                ),
                                if (alert.imageUrl != null) ...[
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    icon: Icons.camera_alt,
                                    label: 'Image',
                                    value: 'Available',
                                  ),
                                ],
                              ],
                            ),
                          ),
                          actions: [
                            if (!alert.handled)
                              TextButton.icon(
                                icon: const Icon(Icons.check, color: Colors.green),
                                label: const Text('Mark as Handled'),
                                onPressed: () {
                                  ref.read(sosAlertsProvider.notifier).markAsHandled(alert.id);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Alert marked as handled'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// Helper widget for detail rows in dialog
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
