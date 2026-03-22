class SalarySlip {
  final String id;
  final String userId;
  final int month;
  final int year;
  final int totalDays;
  final double totalHours;
  final double overtimeHours;
  final int daysAbsent;
  final int daysLate;
  final int leaveDays;
  final double grossAmount;
  final Map<String, dynamic> deductionBreakdown;
  final double deductions;
  final double bonus;
  final double advanceDeduction;
  final double netAmount;
  final String status; // GENERATED | PAID | CANCELLED
  final String? paymentMode; // CASH | BANK | UPI
  final DateTime? paidAt;
  final DateTime generatedAt;
  final Map<String, dynamic>? user;

  SalarySlip({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.totalDays,
    required this.totalHours,
    this.overtimeHours = 0,
    this.daysAbsent = 0,
    this.daysLate = 0,
    this.leaveDays = 0,
    required this.grossAmount,
    this.deductionBreakdown = const {},
    this.deductions = 0,
    this.bonus = 0,
    this.advanceDeduction = 0,
    required this.netAmount,
    this.status = 'GENERATED',
    this.paymentMode,
    this.paidAt,
    required this.generatedAt,
    this.user,
  });

  factory SalarySlip.fromJson(Map<String, dynamic> json) {
    return SalarySlip(
      id: json['id'] as String,
      userId: json['userId'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      totalDays: json['totalDays'] as int,
      totalHours: (json['totalHours'] as num).toDouble(),
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0,
      daysAbsent: json['daysAbsent'] as int? ?? 0,
      daysLate: json['daysLate'] as int? ?? 0,
      leaveDays: json['leaveDays'] as int? ?? 0,
      grossAmount: (json['grossAmount'] as num).toDouble(),
      deductionBreakdown:
          (json['deductionBreakdown'] as Map<String, dynamic>?) ?? {},
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0,
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
      advanceDeduction: (json['advanceDeduction'] as num?)?.toDouble() ?? 0,
      netAmount: (json['netAmount'] as num).toDouble(),
      status: json['status'] as String? ?? 'GENERATED',
      paymentMode: json['paymentMode'] as String?,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  String get monthName {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
