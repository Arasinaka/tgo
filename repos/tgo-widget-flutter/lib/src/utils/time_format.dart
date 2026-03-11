import 'package:intl/intl.dart';

/// Utility class for formatting time
class TimeFormat {
  /// Format message time for display
  ///
  /// Returns:
  /// - "Just now" for messages within 1 minute
  /// - "HH:mm" for messages today
  /// - "Yesterday HH:mm" for messages yesterday
  /// - "MM/dd HH:mm" for messages this year
  /// - "yyyy/MM/dd HH:mm" for older messages
  static String formatMessageTime(DateTime time, {String locale = 'en'}) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return locale == 'zh' ? '刚刚' : 'Just now';
    }

    final isToday = time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = time.year == yesterday.year &&
        time.month == yesterday.month &&
        time.day == yesterday.day;

    final timeStr = DateFormat('HH:mm').format(time);

    if (isToday) {
      return timeStr;
    }

    if (isYesterday) {
      return locale == 'zh' ? '昨天 $timeStr' : 'Yesterday $timeStr';
    }

    if (time.year == now.year) {
      return DateFormat('MM/dd HH:mm').format(time);
    }

    return DateFormat('yyyy/MM/dd HH:mm').format(time);
  }

  /// Format duration in seconds to readable string
  static String formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    if (seconds < 3600) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s > 0 ? '${m}m ${s}s' : '${m}m';
    }
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  /// Format file size to readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

