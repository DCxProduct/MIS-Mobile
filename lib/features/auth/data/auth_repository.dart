import '../../../core/network/api_client.dart';
import 'auth_user.dart';

class AuthRepository {
  AuthRepository(this._api, {this.enableDemoLogin = false});
  final ApiClient _api;

  /// Explicit opt-in for fixture previews/tests. Normal app logins use the API.
  final bool enableDemoLogin;
  AuthUser? _staticUser;

  bool get isStaticSession => _staticUser != null;

  /// Shared transport so feature repositories reuse the authenticated session.
  ApiClient get apiClient => _api;

  Future<AuthUser> login(String email, String password) async {
    final demoEmail = email.trim().toLowerCase();
    if (enableDemoLogin &&
        (demoEmail == 'cdc@gmail.com' || demoEmail == 'cefp@gmail.com')) {
      clearSession();
      if (password != '12345678') {
        throw const ApiException(
          'Invalid email or password.',
          statusCode: 401,
          endpoint: 'auth/login',
        );
      }
      final isCefp = demoEmail == 'cefp@gmail.com';
      return _staticUser = AuthUser(
        id: 0,
        email: demoEmail,
        name: isCefp ? 'CEFP' : 'CDC Section',
        isActive: true,
        roles: [isCefp ? 'cefp' : 'cdc_section'],
      );
    }
    _staticUser = null;
    try {
      await _api.post(
        'auth/login',
        body: {'email': demoEmail, 'password': password},
      );
      return await getCurrentUser();
    } catch (_) {
      _api.clearSession();
      rethrow;
    }
  }

  Future<AuthUser> getCurrentUser() async {
    if (_staticUser != null) return _staticUser!;
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
    if (isStaticSession) {
      clearSession();
      return;
    }
    try {
      await _api.postAction('auth/logout');
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
    }
    _api.clearSession();
  }

  void clearSession() {
    _staticUser = null;
    _api.clearSession();
  }

  void dispose() => _api.close();
}
