import 'package:intl/intl.dart';

class TimeUtils {
  // Asia/Manila timezone (UTC+8)
  static const String manilaTimeZone = 'Asia/Manila';
  
  /// Format a DateTime to Asia/Manila timezone
  static String formatToManilaTime(DateTime dateTime, {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    // Ensure we're working with UTC time, then convert to Manila time (UTC+8)
    final utcTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
    final manilaTime = utcTime.add(const Duration(hours: 8));
    final formatter = DateFormat(format);
    return formatter.format(manilaTime);
  }
  
  /// Get current time in Asia/Manila timezone
  static DateTime getManilaTime() {
    return DateTime.now().toUtc().add(const Duration(hours: 8));
  }
  
  /// Format timestamp string to readable Manila time
  static String formatTimestamp(String? timestamp, {String format = 'MMM dd, yyyy HH:mm:ss'}) {
    if (timestamp == null || timestamp.isEmpty) {
      return 'Unknown time';
    }
    
    try {
      // Parse timestamp - DateTime.parse() handles both UTC (with 'Z') and local timestamps
      DateTime dateTime = DateTime.parse(timestamp);
      
      // For timestamps without timezone offset, ensure it's treated as UTC for consistent conversion
      if (!dateTime.isUtc) {
        dateTime = DateTime.utc(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
          dateTime.microsecond,
        );
      }
      
      return formatToManilaTime(dateTime, format: format);
    } catch (e) {
      return timestamp; // Return original if parsing fails
    }
  }
  
  /// Get relative time (e.g., "2 minutes ago") in Manila timezone
  static String getRelativeTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return 'Unknown time';
    }
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final manilaTime = getManilaTime();
      final difference = manilaTime.difference(dateTime.toUtc().add(const Duration(hours: 8)));
      
      if (difference.inSeconds < 60) {
        return '${difference.inSeconds} seconds ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inDays < 30) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else {
        return formatToManilaTime(dateTime, format: 'MMM dd, yyyy');
      }
    } catch (e) {
      return timestamp;
    }
  }
  
  /// Format time for display in panic alert overlay (with proper formatting)
  static String formatAlertTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return 'Unknown time';
    }
    
    // Handle numeric-only timestamps (like "182958" or millis like "98670")
    if (RegExp(r'^\d+$').hasMatch(timestamp)) {
      final number = int.tryParse(timestamp);
      if (number == null) return timestamp;
      
      // If number is less than 1000000, it's likely millis (< 16 minutes)
      // Convert to seconds and format as time
      if (number < 1000000) {
        final totalSeconds = number ~/ 1000;
        final hours = (totalSeconds ~/ 3600) % 24;
        final minutes = (totalSeconds ~/ 60) % 60;
        final seconds = totalSeconds % 60;
        
        // Format with Manila timezone offset
        final now = DateTime.now();
        final manilaTime = DateTime(now.year, now.month, now.day, hours, minutes, seconds);
        return DateFormat('h:mm:ss a').format(manilaTime);
      }
      
      // If 6 digits, format HHMMSS -> HH:MM:SS
      if (timestamp.length == 6) {
        try {
          final hours = timestamp.substring(0, 2);
          final minutes = timestamp.substring(2, 4);
          final seconds = timestamp.substring(4, 6);
          
          final time = DateTime(2025, 1, 1, int.parse(hours), int.parse(minutes), int.parse(seconds));
          return DateFormat('h:mm:ss a').format(time);
        } catch (e) {
          return timestamp;
        }
      }
      
      return timestamp; // Unknown numeric format
    }
    
    // Handle ISO 8601 timestamps
    return formatTimestamp(timestamp, format: 'h:mm:ss a');
  }
}
