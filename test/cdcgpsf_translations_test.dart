import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/filters/api_filter_sheet.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/auth/data/auth_user.dart';
import 'package:gpsf_app/features/cdc_secretariat/issues/issues_screen.dart';
import 'package:gpsf_app/features/cdc_secretariat/meetings/meeting_screen.dart';
import 'package:gpsf_app/features/cdc_secretariat/meetings/summary_issue_details.dart';
import 'package:gpsf_app/features/shared/meetings/data/meeting_summary.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decision.dart';
import 'package:gpsf_app/screens/report/rgc_decision_detail_screen.dart';
import 'package:gpsf_app/features/cdc_secretariat/reports/progress_report_ministries_screen.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_report.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:gpsf_app/translations/cdcgpsf_translation_keys.dart';
import 'package:gpsf_app/translations/translation_repository.dart';
import 'package:gpsf_app/translations/translation_sync.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response ok(Object data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
http.Response dictionary(
  String module,
  String language,
  Map<String, String> labels,
) => ok({
  'success': true,
  'data': {
    'module': module,
    'language': language,
    'page': null,
    'translations': labels,
  },
});
AppSettingsController settingsWith(
  Future<http.Response> Function(http.Request) handler,
) => AppSettingsController(
  authRepository: AuthRepository(ApiClient(client: MockClient(handler))),
)..setModuleType(AppModuleType.cdcSecretariat);

void main() {
  final captured =
      jsonDecode(
            File(
              'test/fixtures/cdcgpsf_translation_labels.json',
            ).readAsStringSync(),
          )
          as Map;
  for (final language in AppLanguage.values) {
    final code = language == AppLanguage.khmer ? 'km' : 'en';
    final labels = Map<String, String>.from(captured[code] as Map);
    testWidgets('$code CDC summary issue reads CDC-only fields from API', (
      tester,
    ) async {
      final settings = settingsWith(
        (_) async => dictionary('cdcgpsf', code, labels),
      )..setLanguage(language);
      addTearDown(settings.dispose);
      await settings.loadTranslations();
      final summary = MeetingSummary(
        jsonDecode(
          File(
            'test/fixtures/cdcgpsf_meeting_summary.json',
          ).readAsStringSync().replaceFirst('\uFEFF', ''),
        ),
      );
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: CdcSummaryIssueDetails(issue: summary.issues.single),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final key in [
        'escalation',
        'solution_reference',
        'rgc_decision',
        'next_step',
        'remark',
      ]) {
        final label = find.text(labels['meeting_summary.issue_dialog.$key']!);
        await tester.scrollUntilVisible(
          label,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(label, findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets(
      '$code CDC RGC report uses report labels independently of decision fields',
      (tester) async {
        var unavailableLabel = 'API $code reference unavailable';
        final settings = settingsWith(
          (_) async => dictionary('cdcgpsf', code, {
            ...labels,
            'issue_matrix_rgc_decision.rgc.detail.indicators':
                'Decision indicator API',
            'issue_matrix_rgc_decision.rgc.report.solutionIndicators':
                'Report indicator API',
            'issue_matrix_rgc_decision.rgc.report.tab':
                'API {semester} / {year}',
            'issue_matrix_rgc_decision.rgc.report.not_available':
                unavailableLabel,
            'issue_matrix_rgc_decision.rgc.detail.rgc_fallback':
                'API $code decision heading',
          }),
        )..setLanguage(language);
        addTearDown(settings.dispose);
        await settings.loadTranslations();
        final detail = RgcDecisionDetail.fromJson({
          'id': 7,
          'stakeholder': {'name': 'MAFF'},
          'indicatorName': 'Decision metric',
          'progressReports': [
            {
              'progressReportId': 4,
              'year': 2028,
              'semester': 'S1',
              'indicators': 'Report metric',
              'referenceName': '',
              'dateOfIssueSolution': '2028-05-16',
            },
          ],
        });
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: Scaffold(
                body: TranslationPageScope(
                  page: 'cdc_rgc_detail',
                  child: CdcGpsfRgcDecisionDetail(detail: detail),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('API $code decision heading'), findsOneWidget);
        final scrollable = find
            .descendant(
              of: find.byKey(const ValueKey('cdc-gpsf-rgc-detail')),
              matching: find.byType(Scrollable),
            )
            .first;
        for (final title in [
          'Decision indicator API',
          'API S1 / 2028',
          labels['issue_matrix_rgc_decision.rgc.report.implementationDate']!,
          unavailableLabel,
          'Report indicator API',
        ]) {
          await tester.scrollUntilVisible(
            find.textContaining(title, findRichText: true),
            250,
            scrollable: scrollable,
          );
          expect(
            find.textContaining(title, findRichText: true),
            findsOneWidget,
          );
        }
        unavailableLabel = 'Updated API $code reference unavailable';
        await settings.loadTranslations(refresh: true);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(unavailableLabel, findRichText: true),
          -250,
          scrollable: scrollable,
        );
        expect(find.text(unavailableLabel, findRichText: true), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    testWidgets(
      '$code CDC meeting tabs keep the web WG Meeting title on every tab',
      (tester) async {
        tester.view.physicalSize = const Size(600, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var calendarTitle = labels['meeting_calendar.title']!;
        final settings = settingsWith((request) async {
          if (request.url.path.endsWith('translations/dictionary')) {
            return dictionary('cdcgpsf', code, {
              ...labels,
              'meeting_calendar.title': calendarTitle,
            });
          }
          return ok(<Object>[]);
        })..setLanguage(language);
        addTearDown(settings.dispose);
        await settings.loadTranslations();
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: const MaterialApp(
              home: Scaffold(body: CdcSecretariatMeetingScreenView()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final title in [
          calendarTitle,
          labels['meeting_summary.title']!,
          labels['meeting_requests.title']!,
        ]) {
          expect(find.text(calendarTitle), findsWidgets);
          expect(find.text(labels['dashboard.title']!), findsNothing);
          await tester.ensureVisible(find.text(title).last);
          await tester.tap(find.text(title).last);
          await tester.pumpAndSettle();
          expect(find.text(title), findsNWidgets(2));
        }
        calendarTitle = 'Updated WG Meeting';
        await settings.loadTranslations(refresh: true);
        await tester.pumpAndSettle();
        expect(find.text(calendarTitle), findsOneWidget);
        expect(find.text(labels['meeting_calendar.title']!), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    test(
      '$code CDC aliases match actual API keys and keep page contexts distinct',
      () async {
        for (final key in {
          ...cdcGpsfCommonKeys.values,
          ...cdcGpsfPageKeys.values.expand((v) => v.values),
          ...cdcGpsfFilterKeys.values.expand((v) => v.values),
        }) {
          expect(labels[key], isNotNull, reason: key);
        }
        final api = ApiClient(
          client: MockClient((request) async {
            expect(request.url.queryParameters, {
              'language': code,
              'module': 'cdcgpsf',
            });
            expect(request.headers['Cache-Control'], 'no-cache, no-store');
            return dictionary('cdcgpsf', code, labels);
          }),
        );
        addTearDown(api.close);
        final fetched = await TranslationRepository(
          api,
        ).dictionary(language, module: 'cdcgpsf');
        AppLocalizations page(String name) => AppLocalizations(
          language,
          module: AppModuleType.cdcSecretariat,
          dictionary: fetched,
          page: name,
        );
        expect(
          page('meeting_calendar').text('meetingRequests'),
          labels['meeting_requests.title'],
        );
        expect(
          page('meeting_calendar').text('filters'),
          labels['meeting_calendar.filter_panel.filters'],
        );
        expect(
          page('cdc_rgc').text('solved'),
          labels['issue_matrix_rgc_decision.stats.solved'],
        );
        expect(
          page('cdc_rgc').status('SOLVED'),
          labels['issue_matrix_rgc_decision.rgc.status.solved'],
        );
        expect(
          page('cdc_rgc_detail').text('focalPersonHE'),
          labels['issue_matrix_rgc_decision.rgc.detail.focal_person'],
        );
        expect(
          page(
            'progress_report',
          ).api('progress_report.shared.decisions.title', fallback: 'missing'),
          labels['progress_reports.shared.decisions.title'],
        );
        expect(
          page('cdc_progress_ministries').text('reportSubmitted'),
          labels['progress_reports.table.detail.ministry_statuses.submitted'],
        );
      },
    );
  }

  test(
    'CDC responses cannot overwrite ministry labels after a module switch',
    () async {
      final cdc = Completer<http.Response>();
      final settings = settingsWith((request) async {
        if (request.url.queryParameters['module'] == 'cdcgpsf') {
          return cdc.future;
        }
        return dictionary('ministry', 'km', {
          'dashboard.title': 'Ministry only',
        });
      });
      addTearDown(settings.dispose);
      final first = settings.loadTranslations();
      await Future<void>.delayed(Duration.zero);
      settings.setModuleType(AppModuleType.lineMinistry);
      await settings.loadTranslations();
      cdc.complete(
        dictionary('cdcgpsf', 'km', {'dashboard.title': 'Old CDC response'}),
      );
      await first;
      expect(settings.translations['dashboard.title'], 'Ministry only');
      settings.setModuleType(AppModuleType.cdcSecretariat);
      expect(settings.translations, isEmpty);
    },
  );

  testWidgets(
    'CDC issue list refreshes labels and opens its own API filter namespace',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.view.physicalSize = const Size(600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var totalLabel = 'CDC web total';
      var fail = false;
      final settings = settingsWith((request) async {
        if (request.url.path.endsWith('translations/dictionary')) {
          expect(request.url.queryParameters['module'], 'cdcgpsf');
          return fail
              ? http.Response('{"success": false}', 503)
              : dictionary('cdcgpsf', 'km', {
                  'issue_matrix_rgc_decision.stats.total_issues': totalLabel,
                  'issue_matrix_rgc_decision.rgc.filter_panel.filter':
                      'CDC filter',
                  'issue_matrix_rgc_decision.rgc.filter_panel.filters':
                      'CDC filter heading',
                  'issue_matrix_rgc_decision.rgc.filter_panel.applyFilters':
                      'CDC apply',
                });
        }
        if (request.url.path.endsWith('/scorecard')) {
          return ok({'total': 0, 'byStatus': []});
        }
        if (request.url.path.endsWith('/filter-options')) {
          return ok({
            'categories': [],
            'statuses': [],
            'governmentAgencies': [],
          });
        }
        return ok({'items': []});
      });
      addTearDown(settings.dispose);
      settings.setCurrentUser(
        const AuthUser(
          id: 5,
          email: 'cdc@example.com',
          name: 'CDC',
          isActive: true,
          roles: ['cdcgpsf'],
        ),
      );
      await settings.loadTranslations();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: TranslationSync(
            controller: settings,
            child: const MaterialApp(
              home: Scaffold(body: CdcSecretariatIssuesScreenView()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(totalLabel), findsOneWidget);
      totalLabel = 'Edited on CDC web';
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(find.text(totalLabel), findsOneWidget);
      expect(find.text('CDC web total'), findsNothing);
      fail = true;
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(find.text(totalLabel), findsOneWidget);
      await tester.tap(find.text('CDC filter'));
      await tester.pumpAndSettle();
      expect(find.byType(ApiFilterSheet), findsOneWidget);
      expect(find.text('CDC filter heading'), findsOneWidget);
      expect(find.text('CDC apply'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'CDC ministries overview uses overview and workflow labels from API',
    (tester) async {
      final reportData =
          jsonDecode(
                File(
                  'test/fixtures/cdc_progress_report.json',
                ).readAsStringSync(),
              )['data']
              as Map<String, dynamic>;
      final settings = settingsWith((request) async {
        if (request.url.path.endsWith('translations/dictionary')) {
          return dictionary('cdcgpsf', 'km', {
            'progress_reports.table.detail.page_title': 'CDC overview API',
            'progress_reports.table.detail.ministry_statuses.requested':
                'CDC requested API',
          });
        }
        if (request.url.path.endsWith('/ministries')) {
          return ok([
            {
              'ministryId': 1,
              'ministry': {'id': 1, 'name': 'Ministry A'},
              'status': 'REQUESTED',
            },
          ]);
        }
        return ok(reportData);
      });
      addTearDown(settings.dispose);
      await settings.loadTranslations();
      tester.view.physicalSize = const Size(700, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: CdcProgressReportMinistriesScreen(
              report: ProgressReport(reportData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CDC overview API'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('CDC requested API'), 250);
      expect(find.text('CDC requested API'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
