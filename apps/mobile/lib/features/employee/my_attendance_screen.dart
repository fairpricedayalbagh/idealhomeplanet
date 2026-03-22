import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/models/attendance.dart';
import '../../shared/utils/date_helpers.dart';

class MyAttendanceScreen extends ConsumerStatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  ConsumerState<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends ConsumerState<MyAttendanceScreen> {
  late int _month;
  late int _year;
  List<Attendance> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ref.read(attendanceRepoProvider).getMyAttendance(
        month: _month,
        year: _year,
      );
      setState(() {
        _records = result['records'] as List<Attendance>;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load attendance'; _loading = false; });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) { _month = 1; _year++; }
      if (_month < 1) { _month = 12; _year--; }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    // Group records by date
    final Map<String, List<Attendance>> grouped = {};
    for (final r in _records) {
      final key = DateHelpers.formatDate(r.timestamp);
      grouped.putIfAbsent(key, () => []).add(r);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance')),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateHelpers.monthYearString(_month, _year),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
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
                    : _records.isEmpty
                        ? const Center(child: Text('No attendance records for this month'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: grouped.keys.length,
                            itemBuilder: (context, index) {
                              final dateKey = grouped.keys.elementAt(index);
                              final dayRecords = grouped[dateKey]!;
                              final checkIn = dayRecords.where((r) => r.type == 'CHECK_IN').firstOrNull;
                              final checkOut = dayRecords.where((r) => r.type == 'CHECK_OUT').firstOrNull;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: checkOut != null
                                            ? Colors.green
                                            : checkIn != null
                                                ? Colors.amber.shade700
                                                : Colors.red,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(dateKey, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (checkIn != null)
                                                Text(
                                                  'In: ${DateHelpers.formatTime(checkIn.timestamp)}',
                                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                                ),
                                              if (checkIn != null && checkOut != null)
                                                Text('  |  ', style: TextStyle(color: Colors.grey[400])),
                                              if (checkOut != null)
                                                Text(
                                                  'Out: ${DateHelpers.formatTime(checkOut.timestamp)}',
                                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (checkIn?.isManual == true || checkOut?.isManual == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Manual', style: TextStyle(fontSize: 11, color: Colors.blue)),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
