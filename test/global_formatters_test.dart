import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/formatters/date_formatter.dart';
import 'package:gpsf_app/core/formatters/number_formatter.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:gpsf_app/features/cdc_section/dashboard/overall_status_card.dart';
import 'package:gpsf_app/features/private_sector/dashboard/widgets/summary_card.dart';
import 'package:gpsf_app/features/line_ministry/dashboard/widgets/summary_card.dart';

void main() {
  testWidgets(
    'summary cards and chart legends change digits without stale English',
    (tester) async {
      final settings = AppSettingsController()
        ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    PrivateSectorSummaryCard(value: '14'),
                    SummaryCard(value: '12'),
                    CdcOverallStatusCard(
                      workingGroup: true,
                      cards: {
                        'totalIssues': 20,
                        'solved': 19,
                        'inProgress': 1,
                        'notAddressed': 0,
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      for (final language in [
        AppLanguage.khmer,
        AppLanguage.english,
        AppLanguage.khmer,
      ]) {
        settings.setLanguage(language);
        await tester.pumpAndSettle();
        final l10n = AppLocalizations(language);
        expect(find.text(l10n.number(14)), findsOneWidget);
        expect(find.text(l10n.number(12)), findsOneWidget);
        expect(find.text('(${l10n.number(20)})'), findsOneWidget);
        expect(find.text('(${l10n.number(19)})'), findsOneWidget);
        final forbiddenDigits = language == AppLanguage.khmer
            ? RegExp('[0-9]')
            : RegExp('[០-៩]');
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          expect(
            forbiddenDigits.hasMatch(text.data ?? ''),
            isFalse,
            reason: text.data,
          );
        }
      }
    },
  );
  test('translation labels localize digits from fallback and API text', () {
    const khmer = AppLocalizations(AppLanguage.khmer);
    const english = AppLocalizations(AppLanguage.english);
    expect(khmer.text('version'), 'កំណែ ១.០');
    expect(khmer.text('twoAttachments'), 'ឯកសារភ្ជាប់ ២');
    expect(english.text('version'), 'Version 1.0');
    expect(
      const AppLocalizations(
        AppLanguage.khmer,
        dictionary: {'custom': 'S2 2027'},
      ).text('custom'),
      'S២ ២០២៧',
    );
    expect(
      const AppLocalizations(
        AppLanguage.english,
        dictionary: {'custom': 'S២ ២០២៧'},
      ).text('custom'),
      'S2 2027',
    );
  });
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
