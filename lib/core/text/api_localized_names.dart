import '../../translations/app_language.dart';
import 'html_text.dart';

/// API names only: retain original values for filtering and request payloads.
class ApiLocalizedNames {
  ApiLocalizedNames(Iterable<dynamic> rows) {
    for (final row in rows) {
      if (row is! Map) continue;
      final name = row['name'];
      final khmer = row['khName'];
      if (name is String && khmer is String && khmer.trim().isNotEmpty) {
        _khmer[name.trim()] = khmer.trim();
      }
    }
  }

  final Map<String, String> _khmer = {};

  String display(String value, AppLanguage language) {
    if (language != AppLanguage.khmer) return value;
    final exact = _khmer[value.trim()];
    if (exact != null) return exact;
    // Some endpoints join names with commas. Names themselves may contain
    // commas, so match the longest complete API name before splitting.
    final names = _khmer.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    var remaining = value.trim();
    final translated = <String>[];
    while (remaining.isNotEmpty) {
      final match = names
          .where((name) => remaining == name || remaining.startsWith('$name, '))
          .firstOrNull;
      if (match == null) return value;
      translated.add(_khmer[match]!);
      remaining = remaining
          .substring(match.length)
          .replaceFirst(RegExp(r'^,\s*'), '');
    }
    return translated.isEmpty ? value : translated.join(', ');
  }
}

/// Select authored API content without translating it or changing stored values.
String apiLocalizedText(String english, String? khmer, AppLanguage language) {
  final kh = khmer ?? '';
  final preferred = language == AppLanguage.khmer ? kh : english;
  final fallback = language == AppLanguage.khmer ? english : kh;
  return htmlToPlainText(preferred).trim().isNotEmpty ? preferred : fallback;
}
