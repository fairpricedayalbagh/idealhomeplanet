import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/leave_provider.dart';
import '../../core/models/leave.dart';
import '../../shared/utils/date_helpers.dart';

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  String _leaveType = 'SICK';
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  bool _submitting = false;

  final _leaveTypes = ['SICK', 'CASUAL', 'PAID', 'UNPAID'];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(leaveRepoProvider).applyLeave(
            leaveType: _leaveType,
            startDate: _startDate!.toIso8601String().split('T')[0],
            endDate: _endDate!.toIso8601String().split('T')[0],
            reason: _reasonController.text.trim(),
          );
      ref.invalidate(myLeavesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave applied successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      String msg = 'Failed to apply leave';
      if (e.toString().contains('INSUFFICIENT_LEAVE')) {
        msg = 'Insufficient leave balance';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leavesAsync = ref.watch(myLeavesProvider);
    LeaveBalances? balances;
    leavesAsync.whenData((data) {
      balances = data['balances'] as LeaveBalances?;
    });

    int? remaining;
    if (balances != null) {
      switch (_leaveType) {
        case 'SICK': remaining = balances!.sick;
        case 'CASUAL': remaining = balances!.casual;
        case 'PAID': remaining = balances!.paid;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Apply Leave')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Leave type
          const Text('Leave Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _leaveType,
            items: _leaveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _leaveType = v!),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          if (remaining != null) ...[
            const SizedBox(height: 6),
            Text('Remaining: $remaining days', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
          const SizedBox(height: 20),

          // Date range
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Start Date', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickDate(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _startDate != null ? DateHelpers.formatDate(_startDate!) : 'Select',
                          style: TextStyle(color: _startDate != null ? null : Colors.grey[500]),
                        ),
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
                    const Text('End Date', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickDate(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _endDate != null ? DateHelpers.formatDate(_endDate!) : 'Select',
                          style: TextStyle(color: _endDate != null ? null : Colors.grey[500]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Reason
          const Text('Reason', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter reason for leave...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
