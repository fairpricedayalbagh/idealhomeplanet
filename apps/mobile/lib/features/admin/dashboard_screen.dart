import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/leave_provider.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/attendance_tile.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final todayAsync = ref.watch(todayAttendanceProvider);
    final pendingAsync = ref.watch(pendingLeavesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayAttendanceProvider);
          ref.invalidate(pendingLeavesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hello, ${auth.user?.name ?? 'Admin'}!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 20),

            // Stats
            todayAsync.when(
              data: (list) {
                final present = list.where((e) => e.status == 'present').length;
                final late = list.where((e) => e.status == 'late').length;
                final absent = list.where((e) => e.status == 'absent').length;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: StatCard(title: 'Total', value: '${list.length}', icon: Icons.people, color: Colors.blue)),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(title: 'Present', value: '$present', icon: Icons.check_circle, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: StatCard(title: 'Late', value: '$late', icon: Icons.access_time, color: Colors.amber.shade700)),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(title: 'Absent', value: '$absent', icon: Icons.cancel, color: Colors.red)),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load stats'),
            ),
            const SizedBox(height: 16),

            // Pending leaves badge
            pendingAsync.when(
              data: (pending) => pending.isNotEmpty
                  ? GestureDetector(
                      onTap: () => context.push('/admin/leaves'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_busy, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${pending.length} pending leave request${pending.length > 1 ? 's' : ''}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.orange),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // Quick actions
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
              children: [
                _QuickAction(icon: Icons.qr_code, label: 'QR Code', onTap: () => context.push('/admin/qr')),
                _QuickAction(icon: Icons.people, label: 'Employees', onTap: () => context.push('/admin/employees')),
                _QuickAction(icon: Icons.fact_check, label: 'Attendance', onTap: () => context.push('/admin/attendance')),
                _QuickAction(icon: Icons.receipt_long, label: 'Salary', onTap: () => context.push('/admin/salary')),
                _QuickAction(icon: Icons.event_note, label: 'Leaves', onTap: () => context.push('/admin/leaves')),
                _QuickAction(icon: Icons.celebration, label: 'Holidays', onTap: () => context.push('/admin/holidays')),
                _QuickAction(icon: Icons.edit_calendar, label: 'Manual', onTap: () => context.push('/admin/manual-attendance')),
                _QuickAction(icon: Icons.history, label: 'Audit Log', onTap: () => context.push('/admin/audit-log')),
              ],
            ),
            const SizedBox(height: 20),

            // Recent check-ins
            Text('Recent Check-ins', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            todayAsync.when(
              data: (list) {
                final checkedIn = list.where((e) => e.checkIn != null).toList();
                if (checkedIn.isEmpty) return const Text('No check-ins yet today');
                return Column(
                  children: checkedIn.take(5).map((e) => AttendanceTile(
                    employeeName: e.employee['name'] ?? '',
                    designation: e.employee['designation'],
                    checkIn: e.checkIn,
                    checkOut: e.checkOut,
                    status: e.status,
                  )).toList(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
