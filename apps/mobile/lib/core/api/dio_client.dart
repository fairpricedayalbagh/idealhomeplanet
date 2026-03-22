import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      if (e.response?.statusCode == 401) {
        // Try to refresh the token
        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString('refresh_token');

        if (refreshToken != null) {
          try {
            // Use a separate Dio instance to avoid interceptor loop
            final refreshDio = Dio(BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

            final response = await refreshDio.post(
              ApiConstants.refresh,
              data: {'refreshToken': refreshToken},
            );

            final newAccessToken = response.data['data']['accessToken'] as String;
            final newRefreshToken = response.data['data']['refreshToken'] as String;

            await prefs.setString('auth_token', newAccessToken);
            await prefs.setString('refresh_token', newRefreshToken);

            // Retry the original request with new token
            final opts = e.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(opts);
            return handler.resolve(retryResponse);
          } on DioException {
            // Refresh failed — clear tokens, user needs to re-login
            await prefs.remove('auth_token');
            await prefs.remove('refresh_token');
            return handler.next(e);
          }
        }
      }
      return handler.next(e);
    },
  ));

  return dio;
});
