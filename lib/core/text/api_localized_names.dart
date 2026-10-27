import '../../translations/app_language.dart';

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
