import '../../translations/app_language.dart';

/// Display only: never use localized digits in API payloads or identifiers.
String formatNumber(
  Object? value, {
  required AppLanguage language,
  int? decimalPlaces,
}) {
  if (value == null) return '—';
  final text = value is num && decimalPlaces != null
      ? value.toStringAsFixed(decimalPlaces)
      : value.toString();
  const english = '0123456789';
  const khmer = '០១២៣៤៥៦៧៨៩';
  return text.split('').map((character) {
    final index = english.indexOf(character);
    final khmerIndex = khmer.indexOf(character);
    final digit = index >= 0 ? index : khmerIndex;
    if (digit < 0) return character;
    return language == AppLanguage.khmer ? khmer[digit] : english[digit];
  }).join();
}
