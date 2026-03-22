import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/holiday_provider.dart';
import '../../shared/utils/date_helpers.dart';

class HolidayManagementScreen extends ConsumerStatefulWidget {
  const HolidayManagementScreen({super.key});

  @override
  ConsumerState<HolidayManagementScreen> createState() => _HolidayManagementScreenState();
}

class _HolidayManagementScreenState extends ConsumerState<HolidayManagementScreen> {
  int _year = DateTime.now().year;

  Future<void> _addHoliday() async {
    final nameController = TextEditingController();
    DateTime? selectedDate;
    bool isOptional = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Holiday'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Holiday Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(_year),
                    lastDate: DateTime(_year, 12, 31),
                  );
                  if (d != null) setDialogState(() => selectedDate = d);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    selectedDate != null ? DateHelpers.formatDate(selectedDate!) : 'Select Date',
                    style: TextStyle(color: selectedDate != null ? null : Colors.grey[500]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Optional Holiday'),
                value: isOptional,
                onChanged: (v) => setDialogState(() => isOptional = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty || selectedDate == null) return;
                Navigator.pop(ctx, {
                  'name': nameController.text.trim(),
                  'date': selectedDate!.toIso8601String().split('T')[0],
                  'isOptional': isOptional,
                });
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();

    if (result == null) return;
    try {
      await ref.read(holidayRepoProvider).addHoliday(
            name: result['name'],
            date: result['date'],
            isOptional: result['isOptional'],
          );
      ref.invalidate(holidaysProvider(_year));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Holiday added!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final holidaysAsync = ref.watch(holidaysProvider(_year));

    return Scaffold(
      appBar: AppBar(title: const Text('Holidays')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHoliday,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Year selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _year--)),
                Text('$_year', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _year++)),
              ],
            ),
          ),

          Expanded(
            child: holidaysAsync.when(
              data: (holidays) => holidays.isEmpty
                  ? const Center(child: Text('No holidays for this year'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: holidays.length,
                      itemBuilder: (context, index) {
                        final h = holidays[index];
                        return Dismissible(
                          key: Key(h.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async => await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Holiday'),
                              content: Text('Delete "${h.name}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ),
                          onDismissed: (_) async {
                            await ref.read(holidayRepoProvider).deleteHoliday(h.id);
                            ref.invalidate(holidaysProvider(_year));
                          },
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
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(child: Icon(Icons.celebration, color: Colors.orange)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                      Text(DateHelpers.formatDate(h.date), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    ],
                                  ),
                                ),
                                if (h.isOptional)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: const Text('Optional', style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
