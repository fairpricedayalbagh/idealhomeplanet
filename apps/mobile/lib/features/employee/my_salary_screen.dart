import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/salary_provider.dart';
import '../../core/models/salary_slip.dart';
import '../../shared/widgets/salary_slip_card.dart';
import '../../shared/utils/date_helpers.dart';

class MySalaryScreen extends ConsumerWidget {
  const MySalaryScreen({super.key});

  void _showBreakdown(BuildContext context, SalarySlip slip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              DateHelpers.monthYearString(slip.month, slip.year),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 20),
            _Row('Days Worked', '${slip.totalDays}'),
            _Row('Hours Worked', DateHelpers.durationString(slip.totalHours)),
            if (slip.overtimeHours > 0) _Row('Overtime', DateHelpers.durationString(slip.overtimeHours)),
            if (slip.daysAbsent > 0) _Row('Days Absent', '${slip.daysAbsent}'),
            if (slip.daysLate > 0) _Row('Days Late', '${slip.daysLate}'),
            if (slip.leaveDays > 0) _Row('Leave Days', '${slip.leaveDays}'),
            const Divider(height: 24),
            _Row('Gross Amount', DateHelpers.currencyFormat(slip.grossAmount), bold: true),

            // Deduction breakdown
            if (slip.deductionBreakdown.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Deductions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              ...slip.deductionBreakdown.entries.map(
                (e) => _Row(
                  e.key.replaceAll('_', ' ').toUpperCase(),
                  '- ${DateHelpers.currencyFormat((e.value as num).toDouble())}',
                  color: Colors.red,
                ),
              ),
            ],

            if (slip.bonus > 0) _Row('Bonus', '+ ${DateHelpers.currencyFormat(slip.bonus)}', color: Colors.green),
            const Divider(height: 24),
            _Row('Net Amount', DateHelpers.currencyFormat(slip.netAmount), bold: true, fontSize: 18),
            const SizedBox(height: 12),
            _Row('Status', slip.status),
            if (slip.paymentMode != null) _Row('Payment Mode', slip.paymentMode!),
            if (slip.paidAt != null) _Row('Paid On', DateHelpers.formatDate(slip.paidAt!)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slipsAsync = ref.watch(mySalarySlipsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Salary Slips')),
      body: slipsAsync.when(
        data: (slips) => slips.isEmpty
            ? const Center(child: Text('No salary slips yet'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(mySalarySlipsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: slips.length,
                  itemBuilder: (context, index) => SalarySlipCard(
                    slip: slips[index],
                    onTap: () => _showBreakdown(context, slips[index]),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load salary slips', style: TextStyle(color: Colors.red[400])),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(mySalarySlipsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  final double? fontSize;

  const _Row(this.label, this.value, {this.bold = false, this.color, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: fontSize ?? 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color,
              fontSize: fontSize ?? 14,
            ),
          ),
        ],
      ),
    );
  }
}
