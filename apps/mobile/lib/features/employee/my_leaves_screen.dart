import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/leave_provider.dart';
import '../../core/models/leave.dart';
import '../../shared/widgets/leave_status_badge.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/utils/date_helpers.dart';

class MyLeavesScreen extends ConsumerWidget {
  const MyLeavesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leavesAsync = ref.watch(myLeavesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Leaves')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/employee/apply-leave'),
        icon: const Icon(Icons.add),
        label: const Text('Apply Leave'),
      ),
      body: leavesAsync.when(
        data: (data) {
          final leaves = data['leaves'] as List<Leave>;
          final balances = data['balances'] as LeaveBalances?;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myLeavesProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Balance cards
                if (balances != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Monthly Credits',
                          value: '${balances.monthlyCredits}',
                          icon: Icons.calendar_month,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'Used',
                          value: '${balances.usedThisMonth}',
                          icon: Icons.event_busy,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'Remaining',
                          value: '${balances.remaining}',
                          icon: Icons.savings_outlined,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Max ${balances.monthlyCredits} leaves per month. Each leave deducts a day\'s pay.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],

                Text('Leave History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                const SizedBox(height: 12),

                if (leaves.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No leave requests yet'),
                  )),

                ...leaves.map((leave) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            leave.leaveType,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          LeaveStatusBadge(status: leave.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateHelpers.formatDateRange(leave.startDate, leave.endDate),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Text(
                        '${leave.totalDays} day${leave.totalDays > 1 ? 's' : ''}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(leave.reason, style: const TextStyle(fontSize: 13)),
                      if (leave.reviewNote != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Note: ${leave.reviewNote}',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load leaves', style: TextStyle(color: Colors.red[400])),
              TextButton(onPressed: () => ref.invalidate(myLeavesProvider), child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
