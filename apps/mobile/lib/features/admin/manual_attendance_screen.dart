import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/models/user.dart';
import '../../shared/utils/date_helpers.dart';

class ManualAttendanceScreen extends ConsumerStatefulWidget {
  const ManualAttendanceScreen({super.key});

  @override
  ConsumerState<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends ConsumerState<ManualAttendanceScreen> {
  User? _selectedEmployee;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _type = 'CHECK_IN';
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee')),
      );
      return;
    }
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }

    final timestamp = DateTime(
      _date.year, _date.month, _date.day, _time.hour, _time.minute,
    );

    setState(() => _submitting = true);
    try {
      await ref.read(attendanceRepoProvider).addManualAttendance(
            userId: _selectedEmployee!.id,
            type: _type,
            timestamp: timestamp.toIso8601String(),
            note: _noteController.text.trim(),
          );
      ref.invalidate(todayAttendanceProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance added!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Manual Attendance')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Employee selector
          const Text('Employee', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          employeesAsync.when(
            data: (employees) => DropdownButtonFormField<User>(
              value: _selectedEmployee,
              hint: const Text('Select employee'),
              items: employees.map((e) => DropdownMenuItem(
                value: e,
                child: Text('${e.name} (${e.phone})'),
              )).toList(),
              onChanged: (v) => setState(() => _selectedEmployee = v),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Failed to load employees'),
          ),
          const SizedBox(height: 20),

          // Type
          const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'CHECK_IN', label: Text('Check In')),
              ButtonSegment(value: 'CHECK_OUT', label: Text('Check Out')),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          const SizedBox(height: 20),

          // Date & Time
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => _date = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(DateHelpers.formatDate(_date)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Time', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _time);
                        if (t != null) setState(() => _time = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(DateHelpers.timeOfDayToString(_time)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Reason
          const Text('Reason *', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Reason for manual entry...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
