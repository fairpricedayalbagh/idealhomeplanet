import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/providers/leave_provider.dart';
import '../../core/models/leave.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/utils/date_helpers.dart';

class EmployeeHomeScreen extends ConsumerWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final leavesAsync = ref.watch(myLeavesProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/employee/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myLeavesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Greeting
            Text(
              'Hello, ${auth.user?.name ?? 'Employee'}!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              DateHelpers.formatDate(now),
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/employee/scan'),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/employee/apply-leave'),
                    icon: const Icon(Icons.event_busy),
                    label: const Text('Apply Leave'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Leave Balances
            Text(
              'Leave Balance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            leavesAsync.when(
              data: (data) {
                final balances = data['balances'] as LeaveBalances?;
                if (balances == null) {
                  return const Text('No balance info available');
                }
                return Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Sick',
                        value: '${balances.sick}',
                        icon: Icons.local_hospital,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        title: 'Casual',
                        value: '${balances.casual}',
                        icon: Icons.beach_access,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        title: 'Paid',
                        value: '${balances.paid}',
                        icon: Icons.paid,
                        color: Colors.green,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading balances', style: TextStyle(color: Colors.red[400])),
            ),
            const SizedBox(height: 24),

            // Quick nav cards
            Text(
              'Quick Access',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            _NavCard(
              icon: Icons.calendar_month,
              title: 'My Attendance',
              subtitle: 'View your attendance history',
              onTap: () => context.push('/employee/attendance'),
            ),
            _NavCard(
              icon: Icons.receipt_long,
              title: 'Salary Slips',
              subtitle: 'View your salary details',
              onTap: () => context.push('/employee/salary'),
            ),
            _NavCard(
              icon: Icons.event_note,
              title: 'My Leaves',
              subtitle: 'View leave history & balance',
              onTap: () => context.push('/employee/leaves'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
