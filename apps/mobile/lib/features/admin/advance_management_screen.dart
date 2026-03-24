import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/advance_provider.dart';
import '../../core/models/advance_request.dart';

class AdvanceManagementScreen extends ConsumerStatefulWidget {
  const AdvanceManagementScreen({super.key});

  @override
  ConsumerState<AdvanceManagementScreen> createState() =>
      _AdvanceManagementScreenState();
}

class _AdvanceManagementScreenState
    extends ConsumerState<AdvanceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _statusFilters = [null, 'PENDING', 'APPROVED', 'REJECTED'];
  final _tabLabels = ['All', 'Pending', 'Approved', 'Rejected'];

  List<AdvanceRequest> _advances = [];
  bool _loading = true;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _tabController.addListener(_onTabChange);
    _loadAdvances();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) _loadAdvances();
  }

  Future<void> _loadAdvances() async {
    setState(() => _loading = true);
    try {
      final status = _statusFilters[_tabController.index];
      final result =
          await ref.read(advanceRepoProvider).getAllAdvances(status: status);
      setState(() {
        _advances = result['advances'] as List<AdvanceRequest>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _approveAdvance(AdvanceRequest advance) async {
    final amountController = TextEditingController(
      text: advance.requestedAmount.toStringAsFixed(0),
    );
    final noteController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Advance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${advance.user?['name'] ?? 'Employee'} requested ₹${advance.requestedAmount.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 4),
            Text(
              'Deduct from: ${_monthNames[advance.deductMonth - 1]} ${advance.deductYear}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              decoration: const InputDecoration(
                labelText: 'Approved Amount (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                helperText: 'You can change the amount before approving',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) {
      amountController.dispose();
      noteController.dispose();
      return;
    }

    final approvedAmount = double.tryParse(amountController.text.trim());
    final reviewNote =
        noteController.text.trim().isEmpty ? null : noteController.text.trim();
    amountController.dispose();
    noteController.dispose();

    try {
      await ref.read(advanceRepoProvider).approveAdvance(
            advance.id,
            approvedAmount: approvedAmount,
            reviewNote: reviewNote,
          );
      ref.invalidate(pendingAdvancesProvider);
      _loadAdvances();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advance approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectAdvance(AdvanceRequest advance) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Advance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reject ${advance.user?['name'] ?? 'Employee'}\'s advance of ₹${advance.requestedAmount.toStringAsFixed(0)}?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) { noteController.dispose(); return; }

    final reviewNote =
        noteController.text.trim().isEmpty ? null : noteController.text.trim();
    noteController.dispose();

    try {
      await ref
          .read(advanceRepoProvider)
          .rejectAdvance(advance.id, reviewNote: reviewNote);
      ref.invalidate(pendingAdvancesProvider);
      _loadAdvances();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advance rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _statusColor(String status) => switch (status) {
        'APPROVED' => Colors.green,
        'REJECTED' => Colors.red,
        _ => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advance Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAdvances,
              child: _advances.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No advance requests found'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _advances.length,
                      itemBuilder: (context, i) {
                        final a = _advances[i];
                        return _AdminAdvanceTile(
                          advance: a,
                          monthNames: _monthNames,
                          statusColor: _statusColor(a.status),
                          onApprove: a.status == 'PENDING'
                              ? () => _approveAdvance(a)
                              : null,
                          onReject: a.status == 'PENDING'
                              ? () => _rejectAdvance(a)
                              : null,
                        );
                      },
                    ),
            ),
    );
  }
}

class _AdminAdvanceTile extends StatelessWidget {
  final AdvanceRequest advance;
  final List<String> monthNames;
  final Color statusColor;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _AdminAdvanceTile({
    required this.advance,
    required this.monthNames,
    required this.statusColor,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final employeeName = advance.user?['name'] as String? ?? 'Employee';
    final designation = advance.user?['designation'] as String?;
    final deductLabel =
        '${monthNames[advance.deductMonth - 1]} ${advance.deductYear}';

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employeeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  if (designation != null)
                    Text(
                      designation,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  advance.status,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.currency_rupee, size: 16),
              Text(
                advance.requestedAmount.toStringAsFixed(0),
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              if (advance.approvedAmount != null &&
                  advance.approvedAmount != advance.requestedAmount) ...[
                const SizedBox(width: 8),
                Text(
                  '→ ₹${advance.approvedAmount!.toStringAsFixed(0)} approved',
                  style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Deduct from: $deductLabel',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(advance.reason, style: const TextStyle(fontSize: 13)),
          if (advance.reviewNote != null) ...[
            const SizedBox(height: 4),
            Text(
              'Note: ${advance.reviewNote}',
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600]),
            ),
          ],
          if (advance.isDeducted) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Already deducted from salary',
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                if (onApprove != null && onReject != null)
                  const SizedBox(width: 10),
                if (onApprove != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
