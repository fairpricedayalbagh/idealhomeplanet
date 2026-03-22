import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';
import '../constants/api_constants.dart';
import '../models/audit_log.dart';

class AuditRepository {
  final Dio _dio;
  AuditRepository(this._dio);

  Future<Map<String, dynamic>> getAuditLogs({
    String? userId,
    String? action,
    String? entityType,
    String? entityId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(ApiConstants.auditLog, queryParameters: {
      if (userId != null) 'userId': userId,
      if (action != null) 'action': action,
      if (entityType != null) 'entityType': entityType,
      if (entityId != null) 'entityId': entityId,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    return {
      'logs': (data['data'] as List).map((e) => AuditLog.fromJson(e)).toList(),
      'total': data['total'],
      'page': data['page'],
      'limit': data['limit'],
    };
  }
}

final auditRepoProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(dioProvider));
});
