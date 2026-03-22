import 'package:flutter/material.dart';

class DateHelpers {
  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> dayNames = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  ];

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${monthShort[date.month - 1]} ${date.year}';
  }

  static String formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }

  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return formatDate(start);
    }
    return '${formatDate(start)} - ${formatDate(end)}';
  }

  static String monthYearString(int month, int year) {
    return '${monthNames[month - 1]} $year';
  }

  static TimeOfDay parseTimeString(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static int workingDaysBetween(DateTime start, DateTime end, List<int> offDays) {
    int count = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDate)) {
      if (!offDays.contains(current.weekday % 7)) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  static String durationString(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String currencyFormat(double amount) {
    return '\u20B9${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }
}
