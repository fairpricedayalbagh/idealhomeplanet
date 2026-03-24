import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ideal_home_planet/core/auth/auth_provider.dart';
import 'package:ideal_home_planet/features/auth/presentation/login_screen.dart';

// Employee screens
import 'package:ideal_home_planet/features/employee/home_screen.dart';
import 'package:ideal_home_planet/features/employee/scan_qr_screen.dart';
import 'package:ideal_home_planet/features/employee/my_attendance_screen.dart';
import 'package:ideal_home_planet/features/employee/my_salary_screen.dart';
import 'package:ideal_home_planet/features/employee/my_leaves_screen.dart';
import 'package:ideal_home_planet/features/employee/apply_leave_screen.dart';
import 'package:ideal_home_planet/features/employee/apply_advance_screen.dart';
import 'package:ideal_home_planet/features/employee/my_advances_screen.dart';
import 'package:ideal_home_planet/features/employee/profile_screen.dart';

// Admin screens
import 'package:ideal_home_planet/features/admin/advance_management_screen.dart';
import 'package:ideal_home_planet/features/admin/dashboard_screen.dart';
import 'package:ideal_home_planet/features/admin/qr_display_screen.dart';
import 'package:ideal_home_planet/features/admin/employee_list_screen.dart';
import 'package:ideal_home_planet/features/admin/employee_form_screen.dart';
import 'package:ideal_home_planet/features/admin/attendance_board_screen.dart';
import 'package:ideal_home_planet/features/admin/manual_attendance_screen.dart';
import 'package:ideal_home_planet/features/admin/salary_management_screen.dart';
import 'package:ideal_home_planet/features/admin/leave_management_screen.dart';
import 'package:ideal_home_planet/features/admin/holiday_management_screen.dart';
import 'package:ideal_home_planet/features/admin/audit_log_screen.dart';

import 'package:ideal_home_planet/core/models/user.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isLoginRoute = state.uri.path == '/login';

      // Not logged in — force login
      if (!isLoggedIn && !isLoginRoute) return '/login';

      // Logged in but on login page — redirect to home
      if (isLoggedIn && isLoginRoute) {
        return authState.isAdmin ? '/admin/dashboard' : '/employee/home';
      }

      // Role-based guards
      if (isLoggedIn) {
        final path = state.uri.path;
        if (authState.isEmployee && path.startsWith('/admin')) {
          return '/employee/home';
        }
        if (authState.isAdmin && path.startsWith('/employee')) {
          return '/admin/dashboard';
        }
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Employee routes
      GoRoute(
        path: '/employee/home',
        name: 'employee-home',
        builder: (context, state) => const EmployeeHomeScreen(),
      ),
      GoRoute(
        path: '/employee/scan',
        name: 'employee-scan',
        builder: (context, state) => const ScanQrScreen(),
      ),
      GoRoute(
        path: '/employee/attendance',
        name: 'employee-attendance',
        builder: (context, state) => const MyAttendanceScreen(),
      ),
      GoRoute(
        path: '/employee/salary',
        name: 'employee-salary',
        builder: (context, state) => const MySalaryScreen(),
      ),
      GoRoute(
        path: '/employee/leaves',
        name: 'employee-leaves',
        builder: (context, state) => const MyLeavesScreen(),
      ),
      GoRoute(
        path: '/employee/apply-leave',
        name: 'employee-apply-leave',
        builder: (context, state) => const ApplyLeaveScreen(),
      ),
      GoRoute(
        path: '/employee/profile',
        name: 'employee-profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/employee/apply-advance',
        name: 'employee-apply-advance',
        builder: (context, state) => const ApplyAdvanceScreen(),
      ),
      GoRoute(
        path: '/employee/advances',
        name: 'employee-advances',
        builder: (context, state) => const MyAdvancesScreen(),
      ),

      // Admin routes
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/qr',
        name: 'admin-qr',
        builder: (context, state) => const QrDisplayScreen(),
      ),
      GoRoute(
        path: '/admin/employees',
        name: 'admin-employees',
        builder: (context, state) => const EmployeeListScreen(),
      ),
      GoRoute(
        path: '/admin/employees/new',
        name: 'admin-employee-new',
        builder: (context, state) => const EmployeeFormScreen(),
      ),
      GoRoute(
        path: '/admin/employees/:id/edit',
        name: 'admin-employee-edit',
        builder: (context, state) {
          final employee = state.extra as User?;
          return EmployeeFormScreen(employee: employee);
        },
      ),
      GoRoute(
        path: '/admin/attendance',
        name: 'admin-attendance',
        builder: (context, state) => const AttendanceBoardScreen(),
      ),
      GoRoute(
        path: '/admin/manual-attendance',
        name: 'admin-manual-attendance',
        builder: (context, state) => const ManualAttendanceScreen(),
      ),
      GoRoute(
        path: '/admin/salary',
        name: 'admin-salary',
        builder: (context, state) => const SalaryManagementScreen(),
      ),
      GoRoute(
        path: '/admin/leaves',
        name: 'admin-leaves',
        builder: (context, state) => const LeaveManagementScreen(),
      ),
      GoRoute(
        path: '/admin/holidays',
        name: 'admin-holidays',
        builder: (context, state) => const HolidayManagementScreen(),
      ),
      GoRoute(
        path: '/admin/audit-log',
        name: 'admin-audit-log',
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        path: '/admin/advances',
        name: 'admin-advances',
        builder: (context, state) => const AdvanceManagementScreen(),
      ),
    ],
  );
});
