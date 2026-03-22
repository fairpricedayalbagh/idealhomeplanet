import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';
import '../constants/api_constants.dart';
import '../models/qr_token.dart';

class QrRepository {
  final Dio _dio;
  QrRepository(this._dio);

  Future<QrToken> getTodayQr() async {
    final response = await _dio.get(ApiConstants.qrToday);
    return QrToken.fromJson(response.data['data']);
  }

  Future<QrToken> rotateQr() async {
    final response = await _dio.post(ApiConstants.qrRotate);
    return QrToken.fromJson(response.data['data']);
  }
}

final qrRepoProvider = Provider<QrRepository>((ref) {
  return QrRepository(ref.watch(dioProvider));
});

final todayQrProvider = FutureProvider<QrToken>((ref) {
  return ref.watch(qrRepoProvider).getTodayQr();
});
