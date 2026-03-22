import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';
import '../constants/api_constants.dart';
import '../models/attendance.dart';

class AttendanceRepository {
  final Dio _dio;
  AttendanceRepository(this._dio);

  Future<Attendance> markAttendance({
    required String qrToken,
    required String type,
    String? deviceId,
  }) async {
    final response = await _dio.post(ApiConstants.attendanceMark, data: {
      'qrToken': qrToken,
      'type': type,
      if (deviceId != null) 'deviceId': deviceId,
    });
    return Attendance.fromJson(response.data['data']);
  }

  Future<Attendance> addManualAttendance({
    required String userId,
    required String type,
    required String timestamp,
    required String note,
  }) async {
    final response = await _dio.post(ApiConstants.attendanceManual, data: {
      'userId': userId,
      'type': type,
      'timestamp': timestamp,
      'note': note,
    });
    return Attendance.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> getMyAttendance({
    int? month,
    int? year,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(ApiConstants.attendanceMy, queryParameters: {
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    return {
      'records': (data['data'] as List).map((e) => Attendance.fromJson(e)).toList(),
      'total': data['total'],
      'page': data['page'],
      'limit': data['limit'],
    };
  }

  Future<Map<String, dynamic>> getAllAttendance({
    String? userId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(ApiConstants.attendanceAll, queryParameters: {
      if (userId != null) 'userId': userId,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    return {
      'records': (data['data'] as List).map((e) => Attendance.fromJson(e)).toList(),
      'total': data['total'],
      'page': data['page'],
      'limit': data['limit'],
    };
  }

  Future<List<TodayAttendance>> getTodayAttendance() async {
    final response = await _dio.get(ApiConstants.attendanceToday);
    return (response.data['data'] as List)
        .map((e) => TodayAttendance.fromJson(e))
        .toList();
  }

  Future<List<AttendanceReport>> getAttendanceReport(int month, int year) async {
    final response = await _dio.get(ApiConstants.attendanceReport, queryParameters: {
      'month': month,
      'year': year,
    });
    return (response.data['data'] as List)
        .map((e) => AttendanceReport.fromJson(e))
        .toList();
  }
}

final attendanceRepoProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(dioProvider));
});

// Today's attendance board for admin
final todayAttendanceProvider = FutureProvider<List<TodayAttendance>>((ref) {
  return ref.watch(attendanceRepoProvider).getTodayAttendance();
});
