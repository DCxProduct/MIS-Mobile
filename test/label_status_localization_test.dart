import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/widgets/filters/api_filter_sheet.dart';
import 'package:gpsf_app/features/cdc_section/reports/rgc_decision_details.dart';
import 'package:gpsf_app/screens/account/profile_detail_screen.dart';
import 'package:gpsf_app/screens/report/meeting_summary_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:gpsf_app/translations/en.dart';
import 'package:gpsf_app/translations/km.dart';

void main() {
  const statuses = {
    'SAVED': 'drafted',
    'NEW_SUBMISSION': 'newSubmission',
    'LIVE': 'live',
    'REVIEWED': 'reviewed',
    'PSWG_REVIEWED': 'pswgReviewed',
    'DRAFT': 'draft',
    'DRAFTED': 'drafted',
    'SUBMITTED': 'submitted',
    'COMPLETED': 'completed',
    'COMPLETE': 'complete',
    'UNDER_REVIEW': 'underReview',
    'SCHEDULED': 'scheduled',
    'SOLVED': 'solved',
    'IN_PROGRESS': 'inProgress',
    'NOT_ADDRESSED': 'notAddressed',
    'SENT': 'sent',
    'SHARED': 'shared',
    'APPROVED': 'approved',
    'REJECTED': 'rejected',
    'PENDING': 'pending',
    'CANCELLED': 'cancelled',
    'EARLY_PROGRESS': 'earlyProgress',
    'MID_PROGRESS': 'midProgress',
  };

  test('status codes and labels translate consistently in both languages', () {
    for (final language in AppLanguage.values) {
      final l10n = AppLocalizations(language);
      for (final entry in statuses.entries) {
        expect(l10n.status(entry.key), l10n.text(entry.value));
        expect(
          l10n.status(entry.key.toLowerCase().replaceAll('_', ' ')),
          l10n.text(entry.value),
        );
        expect(
          l10n.status(enTranslations[entry.value]!),
          l10n.text(entry.value),
        );
      }
      expect(l10n.status('Custom workflow'), 'Custom workflow');
      expect(l10n.status('  '), '—');
    }
    final english = AppLocalizations(AppLanguage.english);
    for (final entry in statuses.entries) {
      expect(
        AppLocalizations(
          AppLanguage.khmer,
        ).status(english.status(kmTranslations[entry.value]!)),
        kmTranslations[entry.value],
      );
    }
  });

  test('every English label has a Khmer translation', () {
    expect(kmTranslations.keys, containsAll(enTranslations.keys));
    expect(
      kmTranslations.values.every((value) => value.trim().isNotEmpty),
      isTrue,
    );
  });

  for (final screen in <(Widget, List<String>)>[
    (
      const ProfileDetailScreen(),
      [
        'profile',
        'personalInformation',
        'gender',
        'dateOfBirth',
        'address',
        'contact',
        'phone',
        'email',
      ],
    ),
    (
      const MeetingSummaryDetailScreen(),
      [
        'meetingSummaryDetails',
        'meetingTime',
        'scheduleMeeting',
        'location',
        'meetingRequestDocument',
      ],
    ),
  ]) {
    testWidgets('${screen.$1.runtimeType} labels update on language switch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController();
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(home: screen.$1),
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
        for (final key in screen.$2) {
          expect(find.text(l10n.text(key)), findsWidgets);
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets(
    'status badge and filters switch without changing selected codes',
    (tester) async {
      final settings = AppSettingsController();
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const CdcRgcStatus(status: 'IN_PROGRESS'),
                  Expanded(
                    child: ApiFilterSheet(
                      initial: FilterSelection(),
                      load: () async => [
                        const FilterSection(
                          id: 'status',
                          title: 'status',
                          options: [
                            FilterOption(value: 'SHARED', label: 'Shared'),
                            FilterOption(
                              value: 'COMPLETED',
                              label: 'Completed',
                            ),
                            FilterOption(
                              value: 'UNDER_REVIEW',
                              label: 'Under Review',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final completed = find.byKey(const ValueKey('filter-status-COMPLETED'));
      await tester.tap(completed);
      for (final language in [
        AppLanguage.khmer,
        AppLanguage.english,
        AppLanguage.khmer,
      ]) {
        settings.setLanguage(language);
        await tester.pumpAndSettle();
        final l10n = AppLocalizations(language);
        for (final key in [
          'inProgress',
          'shared',
          'completed',
          'underReview',
        ]) {
          expect(find.text(l10n.text(key)), findsOneWidget);
        }
        expect(
          find.descendant(of: completed, matching: find.byIcon(Icons.check)),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
