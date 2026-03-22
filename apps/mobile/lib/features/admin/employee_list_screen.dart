import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/employee_provider.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListProvider(_search.isEmpty ? null : _search));

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/employees/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: employeesAsync.when(
              data: (employees) => employees.isEmpty
                  ? const Center(child: Text('No employees found'))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(employeeListProvider(_search.isEmpty ? null : _search)),
                      child: ListView.builder(
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final emp = employees[index];
                          return Dismissible(
                            key: Key(emp.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Deactivate Employee'),
                                  content: Text('Deactivate ${emp.name}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Deactivate', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) async {
                              await ref.read(employeeRepoProvider).deactivateEmployee(emp.id);
                              ref.invalidate(employeeListProvider(_search.isEmpty ? null : _search));
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                child: Text(
                                  emp.name[0].toUpperCase(),
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${emp.phone}${emp.designation != null ? ' • ${emp.designation}' : ''}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: emp.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  emp.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: emp.isActive ? Colors.green : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: () => context.push('/admin/employees/${emp.id}/edit', extra: emp),
                            ),
                          );
                        },
                      ),
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
