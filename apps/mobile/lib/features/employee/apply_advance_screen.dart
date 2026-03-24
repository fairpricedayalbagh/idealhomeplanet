import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/advance_provider.dart';

class ApplyAdvanceScreen extends ConsumerStatefulWidget {
  const ApplyAdvanceScreen({super.key});

  @override
  ConsumerState<ApplyAdvanceScreen> createState() => _ApplyAdvanceScreenState();
}

class _ApplyAdvanceScreenState extends ConsumerState<ApplyAdvanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _loading = false;

  final now = DateTime.now();
  late int _selectedMonth;
  late int _selectedYear;

  final _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(advanceRepoProvider).applyAdvance(
            requestedAmount: double.parse(_amountController.text.trim()),
            reason: _reasonController.text.trim(),
            deductMonth: _selectedMonth,
            deductYear: _selectedYear,
          );

      ref.invalidate(myAdvancesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advance request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build month options: current month + next 2 months
    final months = List.generate(3, (i) {
      final d = DateTime(now.year, now.month + i);
      return (month: d.month, year: d.year);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Advance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salary Advance Request',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 6),
              Text(
                'The approved amount will be deducted from your selected month\'s salary.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 28),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                decoration: const InputDecoration(
                  labelText: 'Requested Amount (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a valid positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Deduct month selector
              Text('Deduct from Month', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: months.map((m) {
                  final selected = m.month == _selectedMonth && m.year == _selectedYear;
                  return ChoiceChip(
                    label: Text('${_monthNames[m.month - 1]} ${m.year}'),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedMonth = m.month;
                      _selectedYear = m.year;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Reason field
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Why do you need this advance?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please provide a reason' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Request', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
