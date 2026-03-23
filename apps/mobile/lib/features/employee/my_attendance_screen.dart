import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/holiday_provider.dart';
import '../../core/models/attendance.dart';
import '../../core/models/holiday.dart';
import '../../shared/utils/date_helpers.dart';

/// Status for each calendar day.
enum _DayStatus { present, absent, late, weekOff, holiday, leave, future, noData }

class MyAttendanceScreen extends ConsumerStatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  ConsumerState<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends ConsumerState<MyAttendanceScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  List<Attendance> _records = [];
  List<Holiday> _holidays = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final month = _focusedDay.month;
      final year = _focusedDay.year;

      final attendanceResult = await ref
          .read(attendanceRepoProvider)
          .getMyAttendance(month: month, year: year);
      final holidayResult = await ref
          .read(holidayRepoProvider)
          .getHolidays(year: year);

      setState(() {
        _records = attendanceResult['records'] as List<Attendance>;
        _holidays = holidayResult;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load attendance';
        _loading = false;
      });
    }
  }

  /// Build a map of date → day status for the focused month.
  Map<DateTime, _DayStatus> _buildDayStatuses() {
    final auth = ref.read(authProvider);
    final user = auth.user;
    final weeklyOff = user?.weeklyOffDays ?? [0];
    final shiftStart = user?.shiftStart ?? '09:00';
    final graceMins = user?.graceMins ?? 15;
    final now = DateTime.now();
    final month = _focusedDay.month;
    final year = _focusedDay.year;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    // Group attendance records by date (year-month-day)
    final Map<String, List<Attendance>> recordsByDate = {};
    for (final r in _records) {
      final key = '${r.timestamp.year}-${r.timestamp.month}-${r.timestamp.day}';
      recordsByDate.putIfAbsent(key, () => []).add(r);
    }

    // Build holiday date set
    final holidayDates = <String>{};
    for (final h in _holidays) {
      holidayDates.add('${h.date.year}-${h.date.month}-${h.date.day}');
    }

    // Parse shift start + grace for late detection
    final shiftParts = shiftStart.split(':');
    final shiftHour = int.tryParse(shiftParts[0]) ?? 9;
    final shiftMin = int.tryParse(shiftParts.length > 1 ? shiftParts[1] : '0') ?? 0;
    final graceDeadlineMinutes = shiftHour * 60 + shiftMin + graceMins;

    final Map<DateTime, _DayStatus> statuses = {};

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      final dateKey = '$year-$month-$d';
      final normalizedDate = DateTime(year, month, d);

      // Future days
      if (date.isAfter(DateTime(now.year, now.month, now.day))) {
        statuses[normalizedDate] = _DayStatus.future;
        continue;
      }

      // Holiday check
      if (holidayDates.contains(dateKey)) {
        statuses[normalizedDate] = _DayStatus.holiday;
        continue;
      }

      // Weekly off check (0=Sun, 1=Mon, ..., 6=Sat)
      // DateTime.weekday: 1=Mon, 7=Sun → convert to 0=Sun format
      final dayOfWeek = date.weekday == 7 ? 0 : date.weekday;
      if (weeklyOff.contains(dayOfWeek)) {
        statuses[normalizedDate] = _DayStatus.weekOff;
        continue;
      }

      // Check attendance records for this day
      final dayRecords = recordsByDate[dateKey];
      if (dayRecords == null || dayRecords.isEmpty) {
        statuses[normalizedDate] = _DayStatus.absent;
        continue;
      }

      // Has check-in?
      final checkIns = dayRecords.where((r) => r.type == 'CHECK_IN');
      if (checkIns.isEmpty) {
        statuses[normalizedDate] = _DayStatus.absent;
        continue;
      }

      // Check if late
      final firstCheckIn = checkIns.first;
      final checkInMinutes = firstCheckIn.timestamp.hour * 60 + firstCheckIn.timestamp.minute;
      if (checkInMinutes > graceDeadlineMinutes) {
        statuses[normalizedDate] = _DayStatus.late;
      } else {
        statuses[normalizedDate] = _DayStatus.present;
      }
    }

    return statuses;
  }

  /// Get attendance details for a specific day.
  List<Attendance> _getRecordsForDay(DateTime day) {
    return _records.where((r) =>
        r.timestamp.year == day.year &&
        r.timestamp.month == day.month &&
        r.timestamp.day == day.day).toList();
  }

  /// Get holiday for a specific day.
  Holiday? _getHolidayForDay(DateTime day) {
    try {
      return _holidays.firstWhere((h) =>
          h.date.year == day.year &&
          h.date.month == day.month &&
          h.date.day == day.day);
    } catch (_) {
      return null;
    }
  }

  Color _statusColor(_DayStatus status) {
    switch (status) {
      case _DayStatus.present:
        return const Color(0xFF4CAF50); // Green
      case _DayStatus.absent:
        return const Color(0xFFEF5350); // Red
      case _DayStatus.late:
        return const Color(0xFFFF9800); // Orange
      case _DayStatus.weekOff:
        return const Color(0xFF42A5F5); // Blue
      case _DayStatus.holiday:
        return const Color(0xFFAB47BC); // Purple
      case _DayStatus.leave:
        return const Color(0xFF26C6DA); // Cyan
      case _DayStatus.future:
      case _DayStatus.noData:
        return Colors.transparent;
    }
  }

  String _statusLabel(_DayStatus status) {
    switch (status) {
      case _DayStatus.present:
        return 'Present';
      case _DayStatus.absent:
        return 'Absent';
      case _DayStatus.late:
        return 'Late';
      case _DayStatus.weekOff:
        return 'Week Off';
      case _DayStatus.holiday:
        return 'Holiday';
      case _DayStatus.leave:
        return 'Leave';
      case _DayStatus.future:
        return 'Upcoming';
      case _DayStatus.noData:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = _loading ? <DateTime, _DayStatus>{} : _buildDayStatuses();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: Colors.red[400])),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Calendar
                    TableCalendar(
                      firstDay: DateTime(2024, 1, 1),
                      lastDay: DateTime(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          _selectedDay != null && isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _loadData();
                      },
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                        leftChevronIcon: Icon(Icons.chevron_left, color: theme.colorScheme.primary),
                        rightChevronIcon: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        weekendStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          return _buildCalendarDay(day, statuses, false);
                        },
                        todayBuilder: (context, day, focusedDay) {
                          return _buildCalendarDay(day, statuses, false, isToday: true);
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          return _buildCalendarDay(day, statuses, true);
                        },
                        outsideBuilder: (context, day, focusedDay) {
                          return Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(color: Colors.grey[300], fontSize: 14),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Legend
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          _legendDot(const Color(0xFF4CAF50), 'Present'),
                          _legendDot(const Color(0xFFEF5350), 'Absent'),
                          _legendDot(const Color(0xFFFF9800), 'Late'),
                          _legendDot(const Color(0xFF42A5F5), 'Week Off'),
                          _legendDot(const Color(0xFFAB47BC), 'Holiday'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Day detail panel
                    Expanded(
                      child: _selectedDay != null
                          ? _buildDayDetail(_selectedDay!, statuses)
                          : Center(
                              child: Text(
                                'Tap a date to see details',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCalendarDay(
    DateTime day,
    Map<DateTime, _DayStatus> statuses,
    bool isSelected, {
    bool isToday = false,
  }) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final status = statuses[normalizedDay] ?? _DayStatus.noData;
    final color = _statusColor(status);
    final hasStatus = status != _DayStatus.future && status != _DayStatus.noData;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : isSelected
                ? Border.all(color: Colors.grey[700]!, width: 2)
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isToday
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          if (hasStatus)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDayDetail(DateTime day, Map<DateTime, _DayStatus> statuses) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final status = statuses[normalizedDay] ?? _DayStatus.noData;
    final records = _getRecordsForDay(day);
    final holiday = _getHolidayForDay(day);
    final color = _statusColor(status);
    final label = _statusLabel(status);

    final checkIn = records.where((r) => r.type == 'CHECK_IN').firstOrNull;
    final checkOut = records.where((r) => r.type == 'CHECK_OUT').firstOrNull;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header + status badge
          Row(
            children: [
              Text(
                DateHelpers.formatDate(day),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const Spacer(),
              if (label.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          if (holiday != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.celebration, size: 16, color: Colors.purple[300]),
                const SizedBox(width: 6),
                Text(
                  holiday.name,
                  style: TextStyle(color: Colors.purple[300], fontSize: 14),
                ),
              ],
            ),
          ],

          if (checkIn != null || checkOut != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (checkIn != null)
                  _timeChip(
                    'Check In',
                    DateHelpers.formatTime(checkIn.timestamp),
                    const Color(0xFF4CAF50),
                  ),
                if (checkIn != null && checkOut != null) const SizedBox(width: 16),
                if (checkOut != null)
                  _timeChip(
                    'Check Out',
                    DateHelpers.formatTime(checkOut.timestamp),
                    const Color(0xFFEF5350),
                  ),
              ],
            ),
            if (checkIn != null && checkOut != null) ...[
              const SizedBox(height: 8),
              Text(
                'Duration: ${_calcDuration(checkIn.timestamp, checkOut.timestamp)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],

          if (records.isEmpty && status == _DayStatus.absent) ...[
            const SizedBox(height: 12),
            Text(
              'No attendance recorded',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],

          if (checkIn?.isManual == true || checkOut?.isManual == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Manual entry',
                style: TextStyle(fontSize: 11, color: Colors.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeChip(String label, String time, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _calcDuration(DateTime start, DateTime end) {
    final diff = end.difference(start);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
