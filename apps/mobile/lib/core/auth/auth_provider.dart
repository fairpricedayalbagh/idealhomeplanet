import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/dio_client.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';

enum AuthStatus { initial, unauthenticated, authenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final User? user;

  AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
  });

  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isAdmin => user?.role == 'ADMIN';
  bool get isEmployee => user?.role == 'EMPLOYEE';

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    User? user,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;

  AuthNotifier(this._dio) : super(AuthState()) {
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');

    if (token != null && userData != null) {
      try {
        final userMap = _parseJsonString(userData);
        if (userMap != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: User.fromJson(userMap),
          );
          return;
        }
      } catch (_) {}
    }
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  Map<String, dynamic>? _parseJsonString(String jsonStr) {
    try {
      // Simple JSON parse using dart:convert would be cleaner,
      // but avoiding extra imports — we store user data as query string
      // Actually, let's just use the stored map directly
      return null; // Will be handled by storing raw response
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String phone, String pin) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'phone': phone, 'pin': pin},
      );

      final data = response.data['data'];
      final token = data['accessToken'] as String;
      final userJson = data['user'] as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      if (data['refreshToken'] != null) {
        await prefs.setString('refresh_token', data['refreshToken'] as String);
      }

      // Store user role and basic info for session restore
      await prefs.setString('user_id', userJson['id'] as String);
      await prefs.setString('user_role', userJson['role'] as String);
      await prefs.setString('user_name', userJson['name'] as String);

      // Build a minimal User for routing — full profile loaded later
      final user = User(
        id: userJson['id'] as String,
        name: userJson['name'] as String,
        phone: userJson['phone'] as String,
        role: userJson['role'] as String,
        designation: userJson['designation'] as String?,
        profilePhoto: userJson['profilePhoto'] as String?,
        dateOfJoining: DateTime.now(),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ??
          e.response?.data?['message'] ??
          'Login failed. Please check your credentials.';
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: errorMsg.toString(),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    // Revoke refresh token on server
    if (refreshToken != null) {
      try {
        await _dio.post(ApiConstants.logout, data: {'refreshToken': refreshToken});
      } catch (_) {
        // Best effort — still clear local state
      }
    }

    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');

    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('user_id');
    final userRole = prefs.getString('user_role');
    final userName = prefs.getString('user_name');

    if (token != null && userId != null && userRole != null && userName != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: User(
          id: userId,
          name: userName,
          phone: '',
          role: userRole,
          dateOfJoining: DateTime.now(),
        ),
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthNotifier(dio);
});
