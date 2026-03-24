import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/advance_provider.dart';
import '../../core/models/advance_request.dart';

class MyAdvancesScreen extends ConsumerWidget {
  const MyAdvancesScreen({super.key});

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Color _statusColor(String status) => switch (status) {
        'APPROVED' => Colors.green,
        'REJECTED' => Colors.red,
        _ => Colors.orange,
      };

  IconData _statusIcon(String status) => switch (status) {
        'APPROVED' => Icons.check_circle_outline,
        'REJECTED' => Icons.cancel_outlined,
        _ => Icons.hourglass_top_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advancesAsync = ref.watch(myAdvancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Advances')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/employee/apply-advance'),
        icon: const Icon(Icons.add),
        label: const Text('Request Advance'),
      ),
      body: advancesAsync.when(
        data: (advances) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(myAdvancesProvider),
          child: advances.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No advance requests yet'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: advances.length,
                  itemBuilder: (context, i) => _AdvanceTile(
                    advance: advances[i],
                    monthNames: _monthNames,
                    statusColor: _statusColor(advances[i].status),
                    statusIcon: _statusIcon(advances[i].status),
                  ),
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load advances', style: TextStyle(color: Colors.red[400])),
              TextButton(
                onPressed: () => ref.invalidate(myAdvancesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvanceTile extends StatelessWidget {
  final AdvanceRequest advance;
  final List<String> monthNames;
  final Color statusColor;
  final IconData statusIcon;

  const _AdvanceTile({
    required this.advance,
    required this.monthNames,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final deductLabel = '${monthNames[advance.deductMonth - 1]} ${advance.deductYear}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
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
                '₹${advance.requestedAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    advance.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (advance.approvedAmount != null &&
              advance.approvedAmount != advance.requestedAmount)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Approved: ₹${advance.approvedAmount!.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          Text(
            'Deduct from: $deductLabel',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(advance.reason, style: const TextStyle(fontSize: 13)),
          if (advance.reviewNote != null) ...[
            const SizedBox(height: 4),
            Text(
              'Admin note: ${advance.reviewNote}',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
            ),
          ],
          if (advance.isDeducted) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Deducted from salary',
                style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
