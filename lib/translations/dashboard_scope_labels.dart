import '../core/network/api_client.dart';
import 'app_language.dart';
import 'translation_repository.dart';

/// Session cache for the two Ministry dashboard pills that use PSWG labels.
class DashboardScopeLabels {
  DashboardScopeLabels(ApiClient api)
    : _repository = TranslationRepository(api);

  final TranslationRepository _repository;
  final _cache = <AppLanguage, Map<String, String>>{};
  final _requests = <AppLanguage, Future<Map<String, String>>>{};
  int _generation = 0;

  Map<String, String> cached(AppLanguage language) =>
      _cache[language] ?? _defaults(language);

  Map<String, String> _defaults(AppLanguage language) => {
    'dashboard_plenary.title': language == AppLanguage.khmer
        ? 'វេទិការ'
        : 'Plenary',
    'dashboard_working_group.title': language == AppLanguage.khmer
        ? 'កិច្ចប្រជុំការងារតាមវិស័យ'
        : 'Working Group',
  };

  Future<Map<String, String>> refresh(AppLanguage language) =>
      _requests[language] ??= _fetch(language);

  Future<Map<String, String>> _fetch(AppLanguage language) async {
    final generation = _generation;
    try {
      final dictionary = await _repository.dictionary(language, module: 'pswg');
      final labels = Map<String, String>.unmodifiable({
        ..._defaults(language),
        for (final key in _defaults(language).keys)
          if (dictionary[key]?.trim().isNotEmpty == true) key: dictionary[key]!,
      });
      if (generation == _generation) _cache[language] = labels;
      return labels;
    } finally {
      if (generation == _generation) _requests.remove(language);
    }
  }

  void clear() {
    _generation++;
    _cache.clear();
    _requests.clear();
  }
}
