import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';
import '../constants/api_constants.dart';
import '../models/salary_slip.dart';

class SalaryRepository {
  final Dio _dio;
  SalaryRepository(this._dio);

  Future<List<SalarySlip>> getMySalarySlips() async {
    final response = await _dio.get(ApiConstants.salaryMy);
    return (response.data['data'] as List)
        .map((e) => SalarySlip.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getAllSalarySlips({
    int? month,
    int? year,
    String? status,
    String? userId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(ApiConstants.salaryAll, queryParameters: {
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (status != null) 'status': status,
      if (userId != null) 'userId': userId,
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    return {
      'slips': (data['data'] as List).map((e) => SalarySlip.fromJson(e)).toList(),
      'total': data['total'],
      'page': data['page'],
      'limit': data['limit'],
    };
  }

  Future<List<Map<String, dynamic>>> getMonthStatus({required int month, required int year}) async {
    final response = await _dio.get(ApiConstants.salaryMonthStatus, queryParameters: {
      'month': month,
      'year': year,
    });
    return (response.data['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<SalarySlip> previewSalary({required String userId, required int month, required int year}) async {
    final response = await _dio.post(ApiConstants.salaryPreview, data: {
      'userId': userId,
      'month': month,
      'year': year,
    });
    return SalarySlip.fromJson(response.data['data']);
  }

  Future<SalarySlip> generateSingleSalary({
    required String userId,
    required int month,
    required int year,
    Map<String, dynamic>? overrides,
  }) async {
    final response = await _dio.post(ApiConstants.salaryGenerateSingle, data: {
      'userId': userId,
      'month': month,
      'year': year,
      if (overrides != null) 'overrides': overrides,
    });
    return SalarySlip.fromJson(response.data['data']);
  }

  Future<List<Map<String, dynamic>>> generateSalaries(int month, int year) async {
    final response = await _dio.post(ApiConstants.salaryGenerate, data: {
      'month': month,
      'year': year,
    });
    return (response.data['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<SalarySlip> markAsPaid(String id, String paymentMode) async {
    final response = await _dio.put(
      ApiConstants.salaryPay(id),
      data: {'paymentMode': paymentMode},
    );
    return SalarySlip.fromJson(response.data['data']);
  }

  Future<SalarySlip> addBonus(String id, double amount) async {
    final response = await _dio.put(
      ApiConstants.salaryBonus(id),
      data: {'amount': amount},
    );
    return SalarySlip.fromJson(response.data['data']);
  }

  Future<SalarySlip> getSalarySlipPdf(String id) async {
    final response = await _dio.get(ApiConstants.salaryPdf(id));
    return SalarySlip.fromJson(response.data['data']);
  }
}

final salaryRepoProvider = Provider<SalaryRepository>((ref) {
  return SalaryRepository(ref.watch(dioProvider));
});

final mySalarySlipsProvider = FutureProvider<List<SalarySlip>>((ref) {
  return ref.watch(salaryRepoProvider).getMySalarySlips();
});
