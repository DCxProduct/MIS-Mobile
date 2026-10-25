import '../../core/network/api_client.dart';

class SupportContact {
  const SupportContact({required this.email, required this.telegramUri});

  final String email;
  final Uri telegramUri;
  Uri get emailUri => Uri(scheme: 'mailto', path: email);
}

class SupportRepository {
  const SupportRepository(this._api);
  final ApiClient _api;

  Future<SupportContact> fetch() async {
    final data = await _api.get(
      'support',
      headers: const {'Cache-Control': 'no-cache'},
    );
    final email = data['email'];
    final telegramUrl = data['telegramUrl'];
    final telegramUri = telegramUrl is String
        ? Uri.tryParse(telegramUrl.trim())
        : null;
    if (email is! String ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim()) ||
        telegramUri == null ||
        telegramUri.scheme != 'https' ||
        telegramUri.host.isEmpty) {
      throw const ApiException('Invalid support contact response.');
    }
    return SupportContact(email: email.trim(), telegramUri: telegramUri);
  }
}
