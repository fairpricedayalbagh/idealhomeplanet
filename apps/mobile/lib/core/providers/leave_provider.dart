import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';
import '../constants/api_constants.dart';
import '../models/leave.dart';

class LeaveRepository {
  final Dio _dio;
  LeaveRepository(this._dio);

  Future<Leave> applyLeave({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final response = await _dio.post(ApiConstants.leaveApply, data: {
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'reason': reason,
    });
    return Leave.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> getMyLeaves() async {
    final response = await _dio.get(ApiConstants.leaveMy);
    final data = response.data['data'];
    return {
      'leaves': (data['leaves'] as List).map((e) => Leave.fromJson(e)).toList(),
      'balances': data['balances'] != null
          ? LeaveBalances.fromJson(data['balances'])
          : null,
    };
  }

  Future<Map<String, dynamic>> getAllLeaves({
    String? status,
    String? userId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(ApiConstants.leaveAll, queryParameters: {
      if (status != null) 'status': status,
      if (userId != null) 'userId': userId,
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    return {
      'leaves': (data['data'] as List).map((e) => Leave.fromJson(e)).toList(),
      'total': data['total'],
      'page': data['page'],
      'limit': data['limit'],
    };
  }

  Future<List<Leave>> getPendingLeaves() async {
    final response = await _dio.get(ApiConstants.leavePending);
    return (response.data['data'] as List)
        .map((e) => Leave.fromJson(e))
        .toList();
  }

  Future<Leave> approveLeave(String id, {String? reviewNote}) async {
    final response = await _dio.put(ApiConstants.leaveApprove(id), data: {
      if (reviewNote != null) 'reviewNote': reviewNote,
    });
    return Leave.fromJson(response.data['data']);
  }

  Future<Leave> rejectLeave(String id, {String? reviewNote}) async {
    final response = await _dio.put(ApiConstants.leaveReject(id), data: {
      if (reviewNote != null) 'reviewNote': reviewNote,
    });
    return Leave.fromJson(response.data['data']);
  }
}

final leaveRepoProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(ref.watch(dioProvider));
});

final myLeavesProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(leaveRepoProvider).getMyLeaves();
});

final pendingLeavesProvider = FutureProvider<List<Leave>>((ref) {
  return ref.watch(leaveRepoProvider).getPendingLeaves();
});
