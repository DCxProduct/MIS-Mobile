import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/formatters/date_formatter.dart';
import 'package:gpsf_app/core/formatters/number_formatter.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';

void main() {
  test('digits convert both directions without changing punctuation', () {
    expect(
      formatNumber('-1,234.50 / 20 (95%)', language: AppLanguage.khmer),
      '-១,២៣៤.៥០ / ២០ (៩៥%)',
    );
    expect(formatNumber('១២៣.៤៥', language: AppLanguage.english), '123.45');
    expect(
      formatNumber(1.25, language: AppLanguage.khmer, decimalPlaces: 1),
      '១.៣',
    );
    expect(formatNumber(null, language: AppLanguage.khmer), '—');
  });
  test('dates and times are localized and preserve supplied calendar day', () {
    final date = DateTime.utc(2026, 10, 25, 18, 5);
    expect(formatDate(date, language: AppLanguage.khmer), '២៥ តុលា ២០២៦');
    expect(formatDate(date, language: AppLanguage.english), 'Oct 25, 2026');
    expect(
      formatDate(date, language: AppLanguage.english, style: AppDateStyle.long),
      'October 25, 2026',
    );
    expect(
      formatDate(date, language: AppLanguage.khmer, style: AppDateStyle.short),
      '២៥/១០/២០២៦',
    );
    expect(formatTime(date, language: AppLanguage.khmer), '៦:០៥ ល្ងាច');
    expect(
      formatTime(date, language: AppLanguage.english, use24Hour: true),
      '18:05',
    );
    expect(formatDate(null, language: AppLanguage.english), '—');
  });
  testWidgets('visible numbers and dates rebuild on language switch', (
    tester,
  ) async {
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                '${l10n.number(123)} | ${l10n.date(DateTime(2026, 10, 25))}',
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('123 | Oct 25, 2026'), findsOneWidget);
    settings.setLanguage(AppLanguage.khmer);
    await tester.pump();
    expect(find.text('១២៣ | ២៥ តុលា ២០២៦'), findsOneWidget);
    settings.setLanguage(AppLanguage.english);
    await tester.pump();
    expect(find.text('123 | Oct 25, 2026'), findsOneWidget);
  });
}
