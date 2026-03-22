import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/leave_provider.dart';
import '../../core/models/leave.dart';
import '../../shared/widgets/leave_status_badge.dart';
import '../../shared/utils/date_helpers.dart';

class LeaveManagementScreen extends ConsumerStatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  ConsumerState<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends ConsumerState<LeaveManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _statusFilters = [null, 'PENDING', 'APPROVED', 'REJECTED'];
  final _tabLabels = ['All', 'Pending', 'Approved', 'Rejected'];

  List<Leave> _leaves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _tabController.addListener(_onTabChange);
    _loadLeaves();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    setState(() => _loading = true);
    try {
      final status = _statusFilters[_tabController.index];
      final result = await ref.read(leaveRepoProvider).getAllLeaves(status: status);
      setState(() {
        _leaves = result['leaves'] as List<Leave>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _approveLeave(Leave leave) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approve ${leave.user?['name'] ?? 'Employee'}\'s leave?'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve', style: TextStyle(color: Colors.green))),
        ],
      ),
    );
    if (confirm != true) { noteController.dispose(); return; }

    try {
      await ref.read(leaveRepoProvider).approveLeave(leave.id, reviewNote: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null);
      await _loadLeaves();
      ref.invalidate(pendingLeavesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave approved'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    noteController.dispose();
  }

  Future<void> _rejectLeave(Leave leave) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${leave.user?['name'] ?? 'Employee'}\'s leave?'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Reason (optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) { noteController.dispose(); return; }

    try {
      await ref.read(leaveRepoProvider).rejectLeave(leave.id, reviewNote: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null);
      await _loadLeaves();
      ref.invalidate(pendingLeavesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave rejected'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _leaves.isEmpty
              ? const Center(child: Text('No leave requests'))
              : RefreshIndicator(
                  onRefresh: _loadLeaves,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaves.length,
                    itemBuilder: (context, index) {
                      final leave = _leaves[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(leave.user?['name'] ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                LeaveStatusBadge(status: leave.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${leave.leaveType} | ${DateHelpers.formatDateRange(leave.startDate, leave.endDate)} (${leave.totalDays}d)',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(leave.reason, style: const TextStyle(fontSize: 13)),
                            if (leave.reviewNote != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Note: ${leave.reviewNote}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600])),
                              ),

                            if (leave.status == 'PENDING') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _rejectLeave(leave),
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _approveLeave(leave),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      child: const Text('Approve'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
