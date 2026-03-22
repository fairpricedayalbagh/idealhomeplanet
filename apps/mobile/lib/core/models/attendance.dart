class Attendance {
  final String id;
  final String userId;
  final String type; // CHECK_IN | CHECK_OUT
  final DateTime timestamp;
  final String? qrTokenId;
  final String? deviceId;
  final bool isManual;
  final String? addedBy;
  final String? note;

  Attendance({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    this.qrTokenId,
    this.deviceId,
    this.isManual = false,
    this.addedBy,
    this.note,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      qrTokenId: json['qrTokenId'] as String?,
      deviceId: json['deviceId'] as String?,
      isManual: json['isManual'] as bool? ?? false,
      addedBy: json['addedBy'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'qrTokenId': qrTokenId,
        'deviceId': deviceId,
        'isManual': isManual,
        'addedBy': addedBy,
        'note': note,
      };
}

class TodayAttendance {
  final Map<String, dynamic> employee;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status; // present | absent | late

  TodayAttendance({
    required this.employee,
    this.checkIn,
    this.checkOut,
    required this.status,
  });

  factory TodayAttendance.fromJson(Map<String, dynamic> json) {
    return TodayAttendance(
      employee: json['employee'] as Map<String, dynamic>,
      checkIn: json['checkIn'] != null
          ? DateTime.parse(json['checkIn'] as String)
          : null,
      checkOut: json['checkOut'] != null
          ? DateTime.parse(json['checkOut'] as String)
          : null,
      status: json['status'] as String,
    );
  }
}

class AttendanceReport {
  final Map<String, dynamic> employee;
  final int daysPresent;
  final int daysLate;
  final double totalHours;

  AttendanceReport({
    required this.employee,
    required this.daysPresent,
    required this.daysLate,
    required this.totalHours,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    return AttendanceReport(
      employee: json['employee'] as Map<String, dynamic>,
      daysPresent: json['daysPresent'] as int,
      daysLate: json['daysLate'] as int,
      totalHours: (json['totalHours'] as num).toDouble(),
    );
  }
}
