import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/attendance_provider.dart';
import '../../shared/widgets/attendance_tile.dart';
import '../../shared/widgets/stat_card.dart';

class AttendanceBoardScreen extends ConsumerWidget {
  const AttendanceBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayAttendanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(todayAttendanceProvider),
          ),
        ],
      ),
      body: todayAsync.when(
        data: (list) {
          final present = list.where((e) => e.status == 'present').length;
          final late = list.where((e) => e.status == 'late').length;
          final absent = list.where((e) => e.status == 'absent').length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: StatCard(title: 'Present', value: '$present', icon: Icons.check_circle, color: Colors.green)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(title: 'Late', value: '$late', icon: Icons.access_time, color: Colors.amber.shade700)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(title: 'Absent', value: '$absent', icon: Icons.cancel, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 20),
              Text("Today's Attendance", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No employees found')))
              else
                ...list.map((e) => AttendanceTile(
                      employeeName: e.employee['name'] ?? '',
                      designation: e.employee['designation'],
                      checkIn: e.checkIn,
                      checkOut: e.checkOut,
                      status: e.status,
                    )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load attendance', style: TextStyle(color: Colors.red[400])),
              TextButton(onPressed: () => ref.invalidate(todayAttendanceProvider), child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
