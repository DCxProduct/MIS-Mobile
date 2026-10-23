import '../core/network/api_client.dart';
import 'app_language.dart';

/// Uses the same authenticated client as the module's data requests.
class TranslationRepository {
  TranslationRepository(this._api);
  final ApiClient _api;

  Future<Map<String, String>> dictionary(
    AppLanguage language, {
    String module = 'pswg',
  }) async {
    final code = language == AppLanguage.khmer ? 'km' : 'en';
    final response = await _api.get(
      'translations/dictionary',
      query: {'language': code, 'module': module},
      headers: const {
        'Cache-Control': 'no-cache, no-store',
        'Pragma': 'no-cache',
      },
      background: true,
    );
    // ApiClient removes the outer envelope; this endpoint has another one.
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map<String, dynamic> ||
        data['language'] != code ||
        data['module'] != module ||
        data['translations'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid translation dictionary');
    }
    final translations = data['translations'] as Map<String, dynamic>;
    if (translations.values.any((value) => value is! String)) {
      throw const FormatException('Invalid translation value');
    }
    return Map.unmodifiable(translations.cast<String, String>());
  }
}
