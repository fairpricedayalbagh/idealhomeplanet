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
  List<Map<String, dynamic>> _employeeStatuses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(salaryRepoProvider).getMonthStatus(month: _month, year: _year);
      setState(() {
        _employeeStatuses = result;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSlipActions(SalarySlip slip, String userName) {
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
              '$userName - ${DateHelpers.monthYearString(slip.month, slip.year)}',
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

  Future<void> _previewAndGenerate(String userId, String userName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final slip = await ref.read(salaryRepoProvider).previewSalary(userId: userId, month: _month, year: _year);
      if (mounted) Navigator.pop(context); // close loading

      if (mounted) {
        _showGenerateDialog(userId, userName, slip);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showGenerateDialog(String userId, String userName, SalarySlip slip) {
    double bonus = 0;
    double initialDeductions = slip.deductions;
    double customDeductions = 0;
    double netAmount = slip.netAmount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void updateNet() {
              setModalState(() {
                netAmount = slip.grossAmount + bonus - (initialDeductions + customDeductions);
              });
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              builder: (ctx, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text(
                    'Preview Salary: $userName',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  _Row('Days Worked', '${slip.totalDays}'),
                  _Row('Hours', DateHelpers.durationString(slip.totalHours)),
                  if (slip.daysAbsent > 0) _Row('Absent', '${slip.daysAbsent} days'),
                  if (slip.daysLate > 0) _Row('Late', '${slip.daysLate} days'),
                  const Divider(height: 20),
                  _Row('Gross', DateHelpers.currencyFormat(slip.grossAmount)),
                  ...slip.deductionBreakdown.entries.map(
                    (e) => _Row(e.key.replaceAll('_', ' '), '- ${DateHelpers.currencyFormat((e.value as num).toDouble())}'),
                  ),
                  _Row('Net Amount', DateHelpers.currencyFormat(netAmount), bold: true),
                  const SizedBox(height: 20),
                  
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Add Custom Bonus (\u20B9)'),
                    onChanged: (val) {
                      bonus = double.tryParse(val) ?? 0;
                      updateNet();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Add Custom Deductions (\u20B9)'),
                    onChanged: (val) {
                      customDeductions = double.tryParse(val) ?? 0;
                      updateNet();
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      try {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );
                        await ref.read(salaryRepoProvider).generateSingleSalary(
                          userId: userId,
                          month: _month,
                          year: _year,
                          overrides: {
                            if (bonus > 0) 'bonus': bonus,
                            if (customDeductions > 0 || initialDeductions > 0) 'deductions': initialDeductions + customDeductions,
                          },
                        );
                        if (mounted) {
                          Navigator.pop(context); // close loader
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary generated!'), backgroundColor: Colors.green));
                          _loadData();
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    child: const Text('Confirm & Generate'),
                  ),
                ],
              ),
            );
          },
        );
      },
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
      await _loadData();
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
      await _loadData();
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
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salary Management')),
      body: Column(
        children: [
          // Month selector
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
          
          // Slips list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _employeeStatuses.isEmpty
                    ? const Center(child: Text('No active employees found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _employeeStatuses.length,
                        itemBuilder: (context, index) {
                          final item = _employeeStatuses[index];
                          final user = item['user'];
                          final slipData = item['slip'];
                          final slip = slipData != null ? SalarySlip.fromJson(slipData) : null;
                          
                          return Container(
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
                                      Text(user['name'] ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (user['designation'] != null)
                                        Text(user['designation'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                                if (slip != null) ...[
                                  GestureDetector(
                                    onTap: () => _showSlipActions(slip, user['name'] ?? 'Employee'),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(DateHelpers.currencyFormat(slip.netAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
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
                                  ),
                                ] else ...[
                                  ElevatedButton(
                                    onPressed: () => _previewAndGenerate(user['id'], user['name'] ?? 'Employee'),
                                    style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        visualDensity: VisualDensity.compact),
                                    child: const Text('Generate'),
                                  ),
                                ],
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
