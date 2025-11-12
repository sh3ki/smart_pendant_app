import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/activity_provider.dart';
import '../utils/time_utils.dart';
import '../models/app_models.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityHistory = ref.watch(activityHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export history (TODO: share_plus)')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Activity Graph (Fixed - not scrollable)
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activity Over Time', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: activityHistory.isEmpty
                        ? const Center(child: Text('No activity data yet'))
                        : LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: FlTitlesData(
                                // Y-axis: Activity levels (REST, WALK, RUN)
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('Rest', style: TextStyle(fontSize: 10));
                                        case 1:
                                          return const Text('Walk', style: TextStyle(fontSize: 10));
                                        case 2:
                                          return const Text('Run', style: TextStyle(fontSize: 10));
                                        default:
                                          return const Text('');
                                      }
                                    },
                                  ),
                                ),
                                // X-axis: Time in minutes
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      // Calculate minutes from first activity
                                      if (activityHistory.isEmpty) return const Text('');
                                      return Text('${value.toInt()}m', style: const TextStyle(fontSize: 10));
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: true),
                              minY: 0,
                              maxY: 2,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _getActivitySpots(activityHistory),
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          // Recent Activity List (Scrollable)
          Expanded(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  Expanded(
                    child: activityHistory.isEmpty
                        ? const Center(child: Text('No activity recorded yet'))
                        : ListView.builder(
                            itemCount: activityHistory.length > 50 ? 50 : activityHistory.length,
                            itemBuilder: (context, index) {
                              final activity = activityHistory.reversed.toList()[index];
                              return ListTile(
                                leading: Icon(_getActivityIcon(activity.motionState)),
                                title: Text(activity.motionState.toUpperCase()),
                                subtitle: Text(
                                  TimeUtils.formatTimestamp(
                                    activity.timestamp,
                                    format: 'MMM dd, yyyy HH:mm:ss',
                                  ),
                                ),
                                trailing: Text('${activity.displaySpeed.toStringAsFixed(1)} m/s'),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Convert activity spots to time-based graph
  /// X-axis: Minutes from first activity
  /// Y-axis: Activity level (0=REST, 1=WALK, 2=RUN)
  List<FlSpot> _getActivitySpots(List<Telemetry> history) {
    if (history.isEmpty) return [];

    try {
      // Parse first activity timestamp as reference point
      final firstTimestamp = DateTime.parse(history.first.timestamp);
      
      return history.map((activity) {
        try {
          // Calculate minutes elapsed from first activity
          final activityTime = DateTime.parse(activity.timestamp);
          final minutesElapsed = activityTime.difference(firstTimestamp).inMinutes.toDouble();
          
          // Convert activity to Y value (0=REST, 1=WALK, 2=RUN)
          final activityLevel = _activityToValue(activity.motionState);
          
          return FlSpot(minutesElapsed, activityLevel);
        } catch (e) {
          // If timestamp parsing fails, use index
          return FlSpot(0, _activityToValue(activity.motionState));
        }
      }).toList();
    } catch (e) {
      // Fallback: use index-based spots if timestamp parsing fails
      return history
          .asMap()
          .entries
          .map((e) => FlSpot(
                e.key.toDouble(),
                _activityToValue(e.value.motionState),
              ))
          .toList();
    }
  }

  double _activityToValue(String state) {
    switch (state.toLowerCase()) {
      case 'run':
        return 2.0;
      case 'walk':
        return 1.0;
      default:
        return 0.0;
    }
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
