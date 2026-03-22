class AuditLog {
  final String id;
  final String userId;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      userId: json['userId'] as String,
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      details: json['details'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
