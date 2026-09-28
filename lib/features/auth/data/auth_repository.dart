import '../../../core/network/api_client.dart';
import 'auth_user.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  /// Shared transport so feature repositories reuse the authenticated session.
  ApiClient get apiClient => _api;

  Future<AuthUser> login(String email, String password) async {
    try {
      await _api.post(
        'auth/login',
        body: {'email': email, 'password': password},
      );
      return await getCurrentUser();
    } catch (_) {
      _api.clearSession();
      rethrow;
    }
  }

  Future<AuthUser> getCurrentUser() async {
    final data = await _api.get('auth/me');
    try {
      final json = data['user'];
      if (json is! Map<String, dynamic>) throw const FormatException();
      final user = AuthUser.fromJson(json);
      if (!user.isActive) throw const ApiException('This account is inactive.');
      return user;
    } on FormatException {
      throw const ApiException('The server returned an invalid user.');
    }
  }

  Future<void> forgotPassword(String email) => _api.postAction(
    'auth/forgot-password',
    body: {'email': email.trim().toLowerCase()},
  );

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) => _api.postAction(
    'auth/reset-password',
    body: {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
      'newPassword': newPassword,
    },
  );

  Future<void> logout() async {
    try {
      await _api.postAction('auth/logout');
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
    }
    _api.clearSession();
  }

  void clearSession() => _api.clearSession();
  void dispose() => _api.close();
}
