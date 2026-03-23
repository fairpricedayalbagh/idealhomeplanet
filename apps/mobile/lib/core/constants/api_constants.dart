class ApiConstants {
  // Use 10.0.2.2 for Android emulator, localhost for web/desktop
  static const String baseUrl = String.fromEnvironment('API_URL',
      defaultValue: 'https://idealhomeplanet-api.vercel.app/api');

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // QR (Admin)
  static const String qrToday = '/qr/today';
  static const String qrRotate = '/qr/rotate';

  // Attendance
  static const String attendanceMark = '/attendance/mark';
  static const String attendanceManual = '/attendance/manual';
  static const String attendanceMy = '/attendance/my';
  static const String attendanceAll = '/attendance/all';
  static const String attendanceToday = '/attendance/today';
  static const String attendanceReport = '/attendance/report';

  // Employees (Admin)
  static const String employees = '/employees';
  static String employeeById(String id) => '/employees/$id';
  static String employeeShift(String id) => '/employees/$id/shift';
  static String employeeSalary(String id) => '/employees/$id/salary';
  static String employeeOffDays(String id) => '/employees/$id/offdays';
  static String employeeResetPin(String id) => '/employees/$id/reset-pin';

  // Salary
  static const String salaryMy = '/salary/my';
  static const String salaryAll = '/salary/all';
  static const String salaryGenerate = '/salary/generate';
  static const String salaryMonthStatus = '/salary/month-status';
  static const String salaryPreview = '/salary/preview';
  static const String salaryGenerateSingle = '/salary/generate/single';
  static String salaryPay(String id) => '/salary/$id/pay';
  static String salaryBonus(String id) => '/salary/$id/bonus';
  static String salaryPdf(String id) => '/salary/$id/pdf';

  // Leave
  static const String leaveApply = '/leave/apply';
  static const String leaveMy = '/leave/my';
  static const String leaveAll = '/leave/all';
  static const String leavePending = '/leave/pending';
  static String leaveApprove(String id) => '/leave/$id/approve';
  static String leaveReject(String id) => '/leave/$id/reject';

  // Holidays
  static const String holidays = '/holidays';
  static String holidayById(String id) => '/holidays/$id';

  // Audit Log
  static const String auditLog = '/audit-log';

  // App Updates
  static const String appVersion = '/app/version';
}
