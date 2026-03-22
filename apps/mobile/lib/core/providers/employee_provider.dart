import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';

class EmployeeRepository {
  final Dio _dio;
  EmployeeRepository(this._dio);

  Future<List<User>> listEmployees({String? search, bool? isActive}) async {
    final response = await _dio.get(ApiConstants.employees, queryParameters: {
      if (search != null) 'search': search,
      if (isActive != null) 'isActive': isActive,
    });
    return (response.data['data'] as List)
        .map((e) => User.fromJson(e))
        .toList();
  }

  Future<User> createEmployee(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.employees, data: data);
    return User.fromJson(response.data['data']);
  }

  Future<User> updateEmployee(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConstants.employeeById(id), data: data);
    return User.fromJson(response.data['data']);
  }

  Future<User> updateShift(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConstants.employeeShift(id), data: data);
    return User.fromJson(response.data['data']);
  }

  Future<User> updateSalaryConfig(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConstants.employeeSalary(id), data: data);
    return User.fromJson(response.data['data']);
  }

  Future<User> updateOffDays(String id, List<int> weeklyOffDays) async {
    final response = await _dio.put(
      ApiConstants.employeeOffDays(id),
      data: {'weeklyOffDays': weeklyOffDays},
    );
    return User.fromJson(response.data['data']);
  }

  Future<void> resetPin(String id, String pin) async {
    await _dio.put(ApiConstants.employeeResetPin(id), data: {'pin': pin});
  }

  Future<void> deactivateEmployee(String id) async {
    await _dio.delete(ApiConstants.employeeById(id));
  }
}

final employeeRepoProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.watch(dioProvider));
});

final employeeListProvider = FutureProvider.family<List<User>, String?>((ref, search) {
  return ref.watch(employeeRepoProvider).listEmployees(search: search, isActive: true);
});
