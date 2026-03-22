import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/salary_provider.dart';
import '../../core/models/salary_slip.dart';
import '../../shared/utils/date_helpers.dart';

class SalaryManagementScreen extends ConsumerStatefulWidget {
  const SalaryManagementScreen({super.key});

  @override
  ConsumerState<SalaryManagementScreen> createState() => _SalaryManagementScreenState();
}

class _SalaryManagementScreenState extends ConsumerState<SalaryManagementScreen> {
  late int _month;
  late int _year;
  List<SalarySlip> _slips = [];
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _loadSlips();
  }

  Future<void> _loadSlips() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(salaryRepoProvider).getAllSalarySlips(month: _month, year: _year);
      setState(() {
        _slips = result['slips'] as List<SalarySlip>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _generateSalaries() async {
    setState(() => _generating = true);
    try {
      final results = await ref.read(salaryRepoProvider).generateSalaries(_month, _year);
      await _loadSlips();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generated ${results.length} salary slips'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _generating = false);
  }

  void _showSlipActions(SalarySlip slip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.85,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(
              '${slip.user?['name'] ?? 'Employee'} - ${DateHelpers.monthYearString(slip.month, slip.year)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _Row('Days Worked', '${slip.totalDays}'),
            _Row('Hours', DateHelpers.durationString(slip.totalHours)),
            if (slip.overtimeHours > 0) _Row('Overtime', DateHelpers.durationString(slip.overtimeHours)),
            if (slip.daysAbsent > 0) _Row('Absent', '${slip.daysAbsent} days'),
            if (slip.daysLate > 0) _Row('Late', '${slip.daysLate} days'),
            const Divider(height: 20),
            _Row('Gross', DateHelpers.currencyFormat(slip.grossAmount)),
            ...slip.deductionBreakdown.entries.map(
              (e) => _Row(e.key.replaceAll('_', ' '), '- ${DateHelpers.currencyFormat((e.value as num).toDouble())}'),
            ),
            if (slip.bonus > 0) _Row('Bonus', '+ ${DateHelpers.currencyFormat(slip.bonus)}'),
            const Divider(height: 20),
            _Row('Net Amount', DateHelpers.currencyFormat(slip.netAmount), bold: true),
            _Row('Status', slip.status),
            const SizedBox(height: 20),

            // Actions
            if (slip.status == 'GENERATED') ...[
              ElevatedButton(
                onPressed: () => _markPaid(slip),
                child: const Text('Mark as Paid'),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton(
              onPressed: () => _addBonus(slip),
              child: const Text('Add Bonus'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markPaid(SalarySlip slip) async {
    final mode = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Payment Mode'),
        children: ['CASH', 'BANK', 'UPI'].map((m) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, m),
          child: Text(m),
        )).toList(),
      ),
    );
    if (mode == null) return;

    try {
      await ref.read(salaryRepoProvider).markAsPaid(slip.id, mode);
      await _loadSlips();
      if (mounted) {
        Navigator.of(context).pop(); // close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as paid!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _addBonus(SalarySlip slip) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Bonus'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount', prefixText: '\u20B9 '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || amount <= 0) return;

    try {
      await ref.read(salaryRepoProvider).addBonus(slip.id, amount);
      await _loadSlips();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bonus added!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) { _month = 1; _year++; }
      if (_month < 1) { _month = 12; _year--; }
    });
    _loadSlips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salary Management')),
      body: Column(
        children: [
          // Month selector + Generate button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                Expanded(
                  child: Text(
                    DateHelpers.monthYearString(_month, _year),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generating ? null : _generateSalaries,
                child: _generating
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Generate Salaries'),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Slips list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _slips.isEmpty
                    ? const Center(child: Text('No salary slips for this month'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _slips.length,
                        itemBuilder: (context, index) {
                          final slip = _slips[index];
                          return GestureDetector(
                            onTap: () => _showSlipActions(slip),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(slip.user?['name'] ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text('${slip.totalDays} days | ${DateHelpers.durationString(slip.totalHours)}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(DateHelpers.currencyFormat(slip.netAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: slip.status == 'PAID' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          slip.status,
                                          style: TextStyle(
                                            color: slip.status == 'PAID' ? Colors.green : Colors.orange,
                                            fontSize: 11, fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
