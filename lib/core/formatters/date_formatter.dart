import '../../translations/app_language.dart';
import 'number_formatter.dart';

enum AppDateStyle { short, medium, long }

/// Formats the supplied calendar date without implicitly changing its timezone.
String formatDate(
  DateTime? date, {
  required AppLanguage language,
  AppDateStyle style = AppDateStyle.medium,
}) {
  if (date == null) return '—';
  const en = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  const km = [
    'មករា',
    'កុម្ភៈ',
    'មីនា',
    'មេសា',
    'ឧសភា',
    'មិថុនា',
    'កក្កដា',
    'សីហា',
    'កញ្ញា',
    'តុលា',
    'វិច្ឆិកា',
    'ធ្នូ',
  ];
  if (style == AppDateStyle.short) {
    return formatNumber(
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
      language: language,
    );
  }
  if (language == AppLanguage.khmer) {
    return formatNumber(
      '${date.day} ${km[date.month - 1]} ${date.year}',
      language: language,
    );
  }
  final month = style == AppDateStyle.long
      ? en[date.month - 1]
      : en[date.month - 1].substring(0, 3);
  return '$month ${date.day}, ${date.year}';
}

String formatTime(
  DateTime? date, {
  required AppLanguage language,
  bool use24Hour = false,
}) {
  if (date == null) return '—';
  final hour = use24Hour
      ? date.hour
      : (date.hour % 12 == 0 ? 12 : date.hour % 12);
  final period = use24Hour
      ? ''
      : language == AppLanguage.khmer
      ? (date.hour < 12 ? ' ព្រឹក' : ' ល្ងាច')
      : (date.hour < 12 ? ' AM' : ' PM');
  return formatNumber(
    '$hour:${date.minute.toString().padLeft(2, '0')}$period',
    language: language,
  );
}

String formatDateTime(
  DateTime? date, {
  required AppLanguage language,
  bool use24Hour = false,
}) => date == null
    ? '—'
    : '${formatDate(date, language: language)} | ${formatTime(date, language: language, use24Hour: use24Hour)}';
