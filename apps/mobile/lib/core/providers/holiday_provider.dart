import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';
import '../constants/api_constants.dart';
import '../models/holiday.dart';

class HolidayRepository {
  final Dio _dio;
  HolidayRepository(this._dio);

  Future<List<Holiday>> getHolidays({int? year}) async {
    final response = await _dio.get(ApiConstants.holidays, queryParameters: {
      if (year != null) 'year': year,
    });
    return (response.data['data'] as List)
        .map((e) => Holiday.fromJson(e))
        .toList();
  }

  Future<Holiday> addHoliday({
    required String name,
    required String date,
    bool isOptional = false,
  }) async {
    final response = await _dio.post(ApiConstants.holidays, data: {
      'name': name,
      'date': date,
      'isOptional': isOptional,
    });
    return Holiday.fromJson(response.data['data']);
  }

  Future<void> deleteHoliday(String id) async {
    await _dio.delete(ApiConstants.holidayById(id));
  }
}

final holidayRepoProvider = Provider<HolidayRepository>((ref) {
  return HolidayRepository(ref.watch(dioProvider));
});

final holidaysProvider = FutureProvider.family<List<Holiday>, int>((ref, year) {
  return ref.watch(holidayRepoProvider).getHolidays(year: year);
});
