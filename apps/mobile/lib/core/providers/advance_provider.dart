import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';
import '../constants/api_constants.dart';
import '../models/advance_request.dart';

class AdvanceRepository {
  final Dio _dio;
  AdvanceRepository(this._dio);

  Future<AdvanceRequest> applyAdvance({
    required double requestedAmount,
    required String reason,
    required int deductMonth,
    required int deductYear,
  }) async {
    final response = await _dio.post(ApiConstants.advanceApply, data: {
      'requestedAmount': requestedAmount,
      'reason': reason,
      'deductMonth': deductMonth,
      'deductYear': deductYear,
    });
    return AdvanceRequest.fromJson(response.data['data']);
  }

  Future<List<AdvanceRequest>> getMyAdvances() async {
    final response = await _dio.get(ApiConstants.advanceMy);
    return (response.data['data'] as List)
        .map((e) => AdvanceRequest.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getAllAdvances({
    String? status,
    String? userId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(ApiConstants.advanceAll, queryParameters: {
      if (status != null) 'status': status,
      if (userId != null) 'userId': userId,
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    return {
      'advances': (data['data'] as List)
          .map((e) => AdvanceRequest.fromJson(e))
          .toList(),
      'total': data['total'],
      'page': data['page'],
      'limit': data['limit'],
    };
  }

  Future<List<AdvanceRequest>> getPendingAdvances() async {
    final response = await _dio.get(ApiConstants.advancePending);
    return (response.data['data'] as List)
        .map((e) => AdvanceRequest.fromJson(e))
        .toList();
  }

  Future<AdvanceRequest> approveAdvance(
    String id, {
    double? approvedAmount,
    String? reviewNote,
  }) async {
    final response = await _dio.put(ApiConstants.advanceApprove(id), data: {
      if (approvedAmount != null) 'approvedAmount': approvedAmount,
      if (reviewNote != null) 'reviewNote': reviewNote,
    });
    return AdvanceRequest.fromJson(response.data['data']);
  }

  Future<AdvanceRequest> rejectAdvance(String id, {String? reviewNote}) async {
    final response = await _dio.put(ApiConstants.advanceReject(id), data: {
      if (reviewNote != null) 'reviewNote': reviewNote,
    });
    return AdvanceRequest.fromJson(response.data['data']);
  }
}

final advanceRepoProvider = Provider<AdvanceRepository>((ref) {
  return AdvanceRepository(ref.watch(dioProvider));
});

final myAdvancesProvider = FutureProvider<List<AdvanceRequest>>((ref) {
  return ref.watch(advanceRepoProvider).getMyAdvances();
});

final pendingAdvancesProvider = FutureProvider<List<AdvanceRequest>>((ref) {
  return ref.watch(advanceRepoProvider).getPendingAdvances();
});
