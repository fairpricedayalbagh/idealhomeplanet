class Leave {
  final String id;
  final String userId;
  final String leaveType; // SICK | CASUAL | PAID | UNPAID
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final String status; // PENDING | APPROVED | REJECTED
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final DateTime createdAt;
  final Map<String, dynamic>? user;

  Leave({
    required this.id,
    required this.userId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    this.status = 'PENDING',
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    required this.createdAt,
    this.user,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['id'] as String,
      userId: json['userId'] as String,
      leaveType: json['leaveType'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalDays: json['totalDays'] as int,
      reason: json['reason'] as String,
      status: json['status'] as String? ?? 'PENDING',
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewNote: json['reviewNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'leaveType': leaveType,
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
        'reason': reason,
      };
}

class LeaveBalances {
  final int monthlyCredits;
  final int usedThisMonth;
  final int remaining;

  LeaveBalances({
    required this.monthlyCredits,
    required this.usedThisMonth,
    required this.remaining,
  });

  factory LeaveBalances.fromJson(Map<String, dynamic> json) {
    return LeaveBalances(
      monthlyCredits: (json['monthlyCredits'] as num?)?.toInt() ?? 4,
      usedThisMonth: (json['usedThisMonth'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 4,
    );
  }
}
