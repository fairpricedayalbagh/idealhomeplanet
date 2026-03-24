class AdvanceRequest {
  final String id;
  final String userId;
  final double requestedAmount;
  final double? approvedAmount;
  final String reason;
  final int deductMonth;
  final int deductYear;
  final String status; // PENDING | APPROVED | REJECTED
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final bool isDeducted;
  final DateTime createdAt;
  final Map<String, dynamic>? user;

  AdvanceRequest({
    required this.id,
    required this.userId,
    required this.requestedAmount,
    this.approvedAmount,
    required this.reason,
    required this.deductMonth,
    required this.deductYear,
    this.status = 'PENDING',
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    this.isDeducted = false,
    required this.createdAt,
    this.user,
  });

  factory AdvanceRequest.fromJson(Map<String, dynamic> json) {
    return AdvanceRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      requestedAmount: (json['requestedAmount'] as num).toDouble(),
      approvedAmount: json['approvedAmount'] != null
          ? (json['approvedAmount'] as num).toDouble()
          : null,
      reason: json['reason'] as String,
      deductMonth: json['deductMonth'] as int,
      deductYear: json['deductYear'] as int,
      status: json['status'] as String? ?? 'PENDING',
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewNote: json['reviewNote'] as String?,
      isDeducted: json['isDeducted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  /// The effective amount (approved takes precedence over requested)
  double get effectiveAmount => approvedAmount ?? requestedAmount;
}
