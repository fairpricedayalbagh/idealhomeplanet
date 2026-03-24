import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/models/user.dart';
import '../../shared/utils/date_helpers.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final User? employee;
  const EmployeeFormScreen({super.key, this.employee});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _pin;
  late final TextEditingController _designation;
  late final TextEditingController _bankAccount;
  late final TextEditingController _bankIfsc;
  late final TextEditingController _upiId;
  late final TextEditingController _monthlySalary;
  late final TextEditingController _hourlyRate;
  late final TextEditingController _monthlyLeaveCredits;

  late String _salaryType;
  late TimeOfDay _shiftStart;
  late TimeOfDay _shiftEnd;
  late int _graceMins;
  late List<bool> _offDays; // index 0=Sun, 6=Sat
  bool _saving = false;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _pin = TextEditingController();
    _designation = TextEditingController(text: e?.designation ?? '');
    _bankAccount = TextEditingController(text: e?.bankAccount ?? '');
    _bankIfsc = TextEditingController(text: e?.bankIfsc ?? '');
    _upiId = TextEditingController(text: e?.upiId ?? '');
    _monthlySalary = TextEditingController(text: e?.monthlySalary?.toString() ?? '');
    _hourlyRate = TextEditingController(text: e?.hourlyRate?.toString() ?? '');
    _monthlyLeaveCredits = TextEditingController(text: '${e?.monthlyLeaveCredits ?? 4}');

    _salaryType = e?.salaryType ?? 'MONTHLY';
    _shiftStart = DateHelpers.parseTimeString(e?.shiftStart ?? '09:00');
    _shiftEnd = DateHelpers.parseTimeString(e?.shiftEnd ?? '18:00');
    _graceMins = e?.graceMins ?? 15;

    final offDayNums = e?.weeklyOffDays ?? [];
    _offDays = List.generate(7, (i) => offDayNums.contains(i));
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _email.dispose(); _pin.dispose();
    _designation.dispose(); _bankAccount.dispose(); _bankIfsc.dispose();
    _upiId.dispose(); _monthlySalary.dispose(); _hourlyRate.dispose();
    _monthlyLeaveCredits.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final offDayNums = <int>[];
    for (int i = 0; i < 7; i++) {
      if (_offDays[i]) offDayNums.add(i);
    }

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'salaryType': _salaryType,
      'shiftStart': DateHelpers.timeOfDayToString(_shiftStart),
      'shiftEnd': DateHelpers.timeOfDayToString(_shiftEnd),
      'graceMins': _graceMins,
      'weeklyOffDays': offDayNums,
      'monthlyLeaveCredits': int.tryParse(_monthlyLeaveCredits.text) ?? 4,
    };

    if (_email.text.trim().isNotEmpty) data['email'] = _email.text.trim();
    if (_designation.text.trim().isNotEmpty) data['designation'] = _designation.text.trim();
    if (_bankAccount.text.trim().isNotEmpty) data['bankAccount'] = _bankAccount.text.trim();
    if (_bankIfsc.text.trim().isNotEmpty) data['bankIfsc'] = _bankIfsc.text.trim();
    if (_upiId.text.trim().isNotEmpty) data['upiId'] = _upiId.text.trim();

    if (_salaryType == 'MONTHLY' && _monthlySalary.text.isNotEmpty) {
      data['monthlySalary'] = double.tryParse(_monthlySalary.text);
    }
    if (_salaryType == 'HOURLY' && _hourlyRate.text.isNotEmpty) {
      data['hourlyRate'] = double.tryParse(_hourlyRate.text);
    }
    if (!_isEditing && _pin.text.isNotEmpty) {
      data['pin'] = _pin.text;
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await ref.read(employeeRepoProvider).updateEmployee(widget.employee!.id, data);
      } else {
        await ref.read(employeeRepoProvider).createEmployee(data);
      }
      ref.invalidate(employeeListProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Employee updated!' : 'Employee added!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Employee' : 'Add Employee')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Basic Info
            const _SectionHeader('Basic Info'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone *'),
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().length < 10 ? 'Min 10 digits' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            if (!_isEditing)
              TextFormField(
                controller: _pin,
                decoration: const InputDecoration(labelText: 'PIN (4 digits) *'),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                validator: (v) => v == null || v.length != 4 ? 'Must be 4 digits' : null,
              ),
            TextFormField(controller: _designation, decoration: const InputDecoration(labelText: 'Designation')),
            const SizedBox(height: 20),

            // Salary
            const _SectionHeader('Salary'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'MONTHLY', label: Text('Monthly')),
                ButtonSegment(value: 'HOURLY', label: Text('Hourly')),
              ],
              selected: {_salaryType},
              onSelectionChanged: (v) => setState(() => _salaryType = v.first),
            ),
            const SizedBox(height: 12),
            if (_salaryType == 'MONTHLY')
              TextFormField(
                controller: _monthlySalary,
                decoration: const InputDecoration(labelText: 'Monthly Salary (\u20B9)', prefixText: '\u20B9 '),
                keyboardType: TextInputType.number,
              )
            else
              TextFormField(
                controller: _hourlyRate,
                decoration: const InputDecoration(labelText: 'Hourly Rate (\u20B9)', prefixText: '\u20B9 '),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 20),

            // Shift
            const _SectionHeader('Shift Schedule'),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start'),
                    subtitle: Text(DateHelpers.timeOfDayToString(_shiftStart)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _shiftStart);
                      if (t != null) setState(() => _shiftStart = t);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End'),
                    subtitle: Text(DateHelpers.timeOfDayToString(_shiftEnd)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _shiftEnd);
                      if (t != null) setState(() => _shiftEnd = t);
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Grace Period: '),
                Expanded(
                  child: Slider(
                    value: _graceMins.toDouble(),
                    min: 5, max: 30, divisions: 5,
                    label: '$_graceMins min',
                    onChanged: (v) => setState(() => _graceMins = v.round()),
                  ),
                ),
                Text('$_graceMins min'),
              ],
            ),
            const SizedBox(height: 20),

            // Off Days
            const _SectionHeader('Weekly Off Days'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) => GestureDetector(
                onTap: () => setState(() => _offDays[i] = !_offDays[i]),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _offDays[i] ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      dayLabels[i],
                      style: TextStyle(
                        color: _offDays[i] ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 20),

            // Leave Credits
            const _SectionHeader('Monthly Leave Credits'),
            TextFormField(
              controller: _monthlyLeaveCredits,
              decoration: const InputDecoration(
                labelText: 'Leaves per month',
                helperText: 'Unused leaves are added to salary at month end',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Payment
            const _SectionHeader('Payment Info'),
            TextFormField(controller: _bankAccount, decoration: const InputDecoration(labelText: 'Bank Account')),
            const SizedBox(height: 12),
            TextFormField(controller: _bankIfsc, decoration: const InputDecoration(labelText: 'IFSC Code')),
            const SizedBox(height: 12),
            TextFormField(controller: _upiId, decoration: const InputDecoration(labelText: 'UPI ID')),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Update Employee' : 'Add Employee', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
    );
  }
}
