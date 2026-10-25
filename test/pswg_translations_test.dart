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
import 'package:gpsf_app/features/private_sector/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/features/private_sector/issues/issue_detail_screen.dart';
import 'package:gpsf_app/features/private_sector/issues/issue_progress_report_detail_screen.dart';
import 'package:gpsf_app/features/private_sector/meetings/tabs/calendar_tab.dart';
import 'package:gpsf_app/features/private_sector/reports/meeting_summary_detail_screen.dart';
import 'package:gpsf_app/features/shared/meetings/data/meeting_summary.dart';
import 'package:gpsf_app/screens/report/tabs/report_progress_report_tab.dart';
import 'package:gpsf_app/features/shared/issues/data/working_group_issue.dart';
import 'package:gpsf_app/features/shared/issues/data/issue_progress_report.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_report.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_reports_repository.dart';
import 'package:gpsf_app/screens/report/report_detail_screen.dart';
import 'package:gpsf_app/screens/report/report_item_detail_sheet.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:gpsf_app/translations/translation_repository.dart';
import 'package:gpsf_app/translations/translation_sync.dart';
import 'package:gpsf_app/translations/pswg_translation_keys.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response dictionaryResponse(String language, Map<String, String> values) =>
    http.Response(
      jsonEncode({
        'success': true,
        'data': {
          'success': true,
          'data': {
            'language': language,
            'module': 'pswg',
            'page': null,
            'translations': values,
          },
        },
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

AppSettingsController settingsWith(
  Future<http.Response> Function(http.Request) handler,
) => AppSettingsController(
  authRepository: AuthRepository(ApiClient(client: MockClient(handler))),
);

void main() {
  for (final language in AppLanguage.values) {
    final code = language == AppLanguage.khmer ? 'km' : 'en';
    testWidgets('$code PSWG schedule uses API templates and refreshes labels', (
      tester,
    ) async {
      var template = 'Web meeting {number}';
      final settings =
          settingsWith((request) async {
              if (request.url.path.endsWith('translations/dictionary')) {
                return dictionaryResponse(code, {
                  'progress_report.table.schedule_names.meeting': template,
                  'progress_report.table.schedule_names.revision_deadline':
                      'Web deadline {number}',
                });
              }
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': [
                    {'id': 5, 'year': 2026, 'semester': 'S2'},
                  ],
                }),
                200,
              );
            })
            ..setModuleType(AppModuleType.privateSector)
            ..setLanguage(language);
      addTearDown(settings.dispose);
      await settings.loadTranslations();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ReportProgressReportTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final first = language == AppLanguage.khmer ? '១' : '1st';
      final second = language == AppLanguage.khmer ? '២' : '2nd';
      expect(find.text('Web meeting $first'), findsOneWidget);
      expect(find.text('Web deadline $second'), findsOneWidget);
      template = 'Edited meeting {number}';
      await settings.loadTranslations(refresh: true);
      await tester.pumpAndSettle();
      expect(find.text('Edited meeting $first'), findsOneWidget);
      expect(find.text('Web meeting $first'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('$code PSWG summary labels match the actual document type', (
      tester,
    ) async {
      final settings =
          settingsWith(
              (_) async => dictionaryResponse(code, {
                'meeting_summary.details.meeting_document':
                    'API meeting document',
                'meeting_summary.details.meeting_request_document':
                    'API request letter',
              }),
            )
            ..setModuleType(AppModuleType.privateSector)
            ..setLanguage(language);
      addTearDown(settings.dispose);
      await settings.loadTranslations();
      for (final hasRequest in [false, true]) {
        final summary = MeetingSummary({
          'id': 1,
          'summaryTitle': 'Summary',
          'meeting': {
            'documentReference': {
              'path': '/meeting.pdf',
              'name': 'Meeting.pdf',
            },
          },
          if (hasRequest)
            'meetingRequest': {
              'meetingRequestLetter': {
                'path': '/request.pdf',
                'name': 'Request.pdf',
              },
            },
        });
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: MeetingSummaryDetailScreen(
                key: ValueKey(hasRequest),
                summary: summary,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(hasRequest ? 'API request letter' : 'API meeting document'),
          findsOneWidget,
        );
        expect(
          find.text(hasRequest ? 'API meeting document' : 'API request letter'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'report and issue sheet use separate descriptions and shared API fields',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var decisionListTitle = 'បញ្ជីសេចក្តីសម្រេចរាជរដ្ឋាភិបាល';
      var decisionColumn = 'សេចក្តីសម្រេចរាជរដ្ឋាភិបាល test B';
      final settings = settingsWith((request) async {
        if (request.url.path.endsWith('translations/dictionary')) {
          return dictionaryResponse('km', {
            'progress_report.shared.info.information': 'API info',
            'progress_report.shared.description': 'Report description',
            'progress_report.shared.issues.columns.issue_description':
                'Issue description',
            'progress_report.shared.issues.columns.recommendation':
                'API recommendation',
            'progress_report.shared.issues.columns.status': 'API issue status',
            'progress_report.shared.form.issue_info': 'API issue detail',
            'progress_report.shared.decisions.title': decisionListTitle,
            'progress_report.shared.decisions.columns.rgc_decision':
                decisionColumn,
          });
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 5,
              'title': 'Issue content',
              'description': 'Body',
              'recommendation': 'Advice',
            },
          }),
          200,
        );
      })..setModuleType(AppModuleType.privateSector);
      addTearDown(settings.dispose);
      await settings.loadTranslations();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: ReportDetailScreen(
              title: 'Report',
              report: ProgressReport({
                'id': 1,
                'ministry': {'name': 'MAFF'},
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MAFF API info'), findsOneWidget);
      expect(find.text('CDC API info'), findsOneWidget);
      expect(find.text('Report description'), findsOneWidget);
      expect(find.text(decisionListTitle), findsOneWidget);
      expect(find.text(decisionColumn), findsNothing);
      // Changing a column label must not rename the list tab.
      decisionColumn = 'Updated column only';
      await settings.loadTranslations(refresh: true);
      await tester.pumpAndSettle();
      expect(find.text(decisionListTitle), findsOneWidget);
      expect(find.text(decisionColumn), findsNothing);
      expect(
        AppLocalizations(
          AppLanguage.khmer,
          dictionary: settings.translations,
          page: 'progress_report',
        ).text('rgcDecision'),
        decisionColumn,
      );
      decisionListTitle = 'Updated decision list';
      await settings.loadTranslations(refresh: true);
      await tester.pumpAndSettle();
      expect(find.text(decisionListTitle), findsOneWidget);
      final context = tester.element(find.byType(ReportDetailScreen));
      unawaited(
        showReportItemDetail(
          context,
          item: {'id': 5},
          type: ProgressReportItemType.issue,
        ),
      );
      await tester.pumpAndSettle();
      final sheet = find.byType(DraggableScrollableSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('API issue detail')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('API issue status')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Issue description')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Report description')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('all mapped labels exist in the km and en API snapshots', () {
    // Selected labels fetched from the stage dictionary on 2026-10-22.
    final snapshot =
        jsonDecode(
              File(
                'test/fixtures/pswg_translation_labels.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final keys = {
      'progress_report.shared.decisions.title',
      ...pswgCommonKeys.values,
      for (final page in pswgPageKeys.values) ...page.values,
      for (final page in pswgFilterKeys.values) ...page.values,
    };
    for (final language in ['km', 'en']) {
      for (final key in keys) {
        expect(
          snapshot[language][key],
          isA<String>(),
          reason: '$language $key',
        );
        expect((snapshot[language][key] as String).trim(), isNotEmpty);
      }
    }
  });

  testWidgets(
    'generated report titles refresh but authored titles stay intact',
    (tester) async {
      var template = 'របាយការណ៍ {semester} {year}';
      final settings = settingsWith(
        (_) async =>
            dictionaryResponse('km', {'issue_matrix.report_tab': template}),
      )..setModuleType(AppModuleType.privateSector);
      addTearDown(settings.dispose);
      await settings.loadTranslations();
      final data = {
        'progressReport': {'id': 1, 'semester': 'S2', 'year': 2026},
      };
      Widget detail(IssueProgressReport report) => AppSettings(
        controller: settings,
        child: MaterialApp(
          home: IssueProgressReportDetailScreen(
            title: 'Issue content',
            report: report,
          ),
        ),
      );
      await tester.pumpWidget(detail(IssueProgressReport.fromJson(data)));
      await tester.pumpAndSettle();
      expect(find.text('របាយការណ៍ S2 2026'), findsOneWidget);
      template = 'Updated {year} / {semester}';
      await settings.loadTranslations(refresh: true);
      await tester.pumpAndSettle();
      expect(find.text('Updated 2026 / S2'), findsOneWidget);
      await tester.pumpWidget(
        detail(
          IssueProgressReport.fromJson({
            ...data,
            'title': 'Authored report title',
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Authored report title'), findsOneWidget);
      expect(find.text('Updated 2026 / S2'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('filter headings and options use their own current API labels', (
    tester,
  ) async {
    final settings = settingsWith(
      (_) async => dictionaryResponse('km', {
        'issue_matrix.column.status': 'Detail status',
        'issue_matrix.filter.status': 'Filter status',
        'issue_matrix.value_labels.s1': 'API semester',
      }),
    )..setModuleType(AppModuleType.privateSector);
    addTearDown(settings.dispose);
    await settings.loadTranslations();
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: ApiFilterSheet(
            translationPage: 'issue_matrix',
            initial: FilterSelection(),
            load: () async => const [
              FilterSection(id: 'status', title: 'status', options: []),
              FilterSection(
                id: 'semester',
                title: 'progressReport',
                options: [
                  FilterOption(
                    value: 'S1',
                    label: 'S1',
                    khmerLabel: 'Old option label',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Filter status'), findsOneWidget);
    expect(find.text('Detail status'), findsNothing);
    expect(find.text('API semester'), findsOneWidget);
    expect(find.text('Old option label'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final page in ['wg_issues', 'issue_matrix']) {
    testWidgets('$page detail uses API labels and refetches on refresh', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var version = 1;
      var requests = 0;
      final dictionary = {
        'wg_issues.detail.issue_detail': 'Issue title',
        'wg_issues.detail.meeting_reference_document': 'Reference label',
        'wg_issues.filter.category': 'Category label',
        'wg_issues.column.submitted_date': 'Submitted label',
        'wg_issues.detail.meeting_date': 'Meeting label',
        'issue_matrix.detail.page_title': 'Matrix title',
        'issue_matrix.submitted_detail.meeting_reference_document':
            'Matrix reference',
        'issue_matrix.detail.category': 'Matrix category',
        'issue_matrix.detail.submission_date': 'Matrix submitted',
        'issue_matrix.detail.meeting_date': 'Matrix meeting',
        'meeting_requests.detail.title': 'Wrong request title',
      };
      final settings = settingsWith((request) async {
        if (request.url.path.endsWith('translations/dictionary')) {
          requests++;
          return dictionaryResponse('km', {
            for (final entry in dictionary.entries)
              entry.key: '${entry.value} $version',
          });
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': 1, 'title': 'Issue content'},
          }),
          200,
        );
      })..setModuleType(AppModuleType.privateSector);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: IssueDetailScreen(
              title: 'Issue content',
              category: '',
              translationPage: page,
              issue: WorkingGroupIssue.fromJson({
                'id': 1,
                'title': 'Issue content',
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, 1, reason: 'Entering the detail fetches labels again');
      final title = page == 'wg_issues' ? 'Issue title' : 'Matrix title';
      final reference = page == 'wg_issues'
          ? 'Reference label'
          : 'Matrix reference';
      final category = page == 'wg_issues'
          ? 'Category label'
          : 'Matrix category';
      final submitted = page == 'wg_issues'
          ? 'Submitted label'
          : 'Matrix submitted';
      final meeting = page == 'wg_issues' ? 'Meeting label' : 'Matrix meeting';
      expect(find.text('$title 1'), findsOneWidget);
      expect(find.text('$reference 1:'), findsOneWidget);
      expect(find.text('$category 1'), findsOneWidget);
      expect(
        find.textContaining('$submitted 1', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('$meeting 1', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Wrong request title 1'), findsNothing);

      version = 2;
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(requests, 2);
      expect(find.text('$title 2'), findsOneWidget);
      expect(find.text('$reference 2:'), findsOneWidget);
      expect(find.text('$title 1'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  const pswgUser = AuthUser(
    id: 1,
    email: 'pswg@example.com',
    name: 'PSWG',
    isActive: true,
    roles: ['pswg'],
  );

  testWidgets(
    'web edits update visible labels without login or language changes',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      var label = 'Original web label';
      var fail = false;
      final settings = settingsWith((request) async {
        expect(request.headers['Cache-Control'], 'no-cache, no-store');
        return fail
            ? http.Response('{"success":false}', 503)
            : dictionaryResponse('km', {'dashboard.title': label});
      });
      addTearDown(settings.dispose);
      settings.setCurrentUser(pswgUser);
      await settings.loadTranslations();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: TranslationSync(
            controller: settings,
            child: MaterialApp(
              home: Builder(
                builder: (context) =>
                    Text(AppLocalizations.of(context).text('dashboard')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original web label'), findsOneWidget);

      var notifications = 0;
      settings.addListener(() => notifications++);
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(
        notifications,
        0,
        reason: 'Unchanged dictionaries must not rebuild the app',
      );
      label = 'Edited on web';
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(find.text('Edited on web'), findsOneWidget);
      expect(find.text('Original web label'), findsNothing);

      fail = true;
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(find.text('Edited on web'), findsOneWidget);
      fail = false;
      label = 'Updated after reconnect';
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(find.text('Updated after reconnect'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'refresh pauses in background and stops on logout or dispose',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      var requests = 0;
      final settings = settingsWith((_) async {
        requests++;
        return dictionaryResponse('km', {'dashboard.title': '$requests'});
      });
      addTearDown(settings.dispose);
      settings.setCurrentUser(pswgUser);
      await settings.loadTranslations();
      await tester.pumpWidget(
        TranslationSync(controller: settings, child: const SizedBox.shrink()),
      );
      await tester.pumpAndSettle();
      var before = requests;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 20));
      expect(requests, before);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(requests, before + 1, reason: 'Resume must refresh immediately');

      settings.clearSession();
      before = requests;
      await tester.pump(const Duration(seconds: 20));
      expect(requests, before);
      settings.setCurrentUser(pswgUser);
      await tester.pumpAndSettle();
      before = requests;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 20));
      expect(requests, before);
    },
  );

  test(
    'simultaneous refreshes share an in-flight dictionary request',
    () async {
      final response = Completer<http.Response>();
      var requests = 0;
      final settings = settingsWith((_) {
        requests++;
        return response.future;
      });
      addTearDown(settings.dispose);
      settings.setModuleType(AppModuleType.privateSector);
      final first = settings.loadTranslations(refresh: true);
      final second = settings.loadTranslations(refresh: true);
      expect(identical(first, second), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(requests, 1);
      response.complete(
        dictionaryResponse('km', {'dashboard.title': 'Fresh label'}),
      );
      await Future.wait([first, second]);
      expect(settings.translations['dashboard.title'], 'Fresh label');
    },
  );

  testWidgets(
    'web dashboard titles remain scrollable on mobile and keep their scopes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = settingsWith((request) async {
        if (request.url.path.endsWith('translations/dictionary')) {
          return dictionaryResponse('km', {
            'dashboard_plenary.title': 'សម័យប្រជុំពេញអង្គ',
            'dashboard_working_group.title': 'កិច្ចប្រជុំការងារតាមវិស័យ',
            'dashboard_plenary.overall_status': 'Plenary API status',
            'dashboard_working_group.overall_status': 'WG API status',
          });
        }
        return http.Response(
          File(
            request.url.path.contains('/plenary/')
                ? 'test/fixtures/plenary.json'
                : 'test/fixtures/working_groups.json',
          ).readAsStringSync(),
          200,
        );
      });
      addTearDown(settings.dispose);
      settings.setModuleType(AppModuleType.privateSector);
      await settings.loadTranslations();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: Scaffold(body: DashboardPage())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('សម័យប្រជុំពេញអង្គ'), findsWidgets);
      expect(find.text('Plenary API status'), findsOneWidget);
      await tester.ensureVisible(find.text('កិច្ចប្រជុំការងារតាមវិស័យ').first);
      await tester.tap(find.text('កិច្ចប្រជុំការងារតាមវិស័យ').first);
      await tester.pumpAndSettle();
      expect(find.text('WG API status'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('calendar uses API month and weekday labels', (tester) async {
    final settings = settingsWith((request) async {
      if (request.url.path.endsWith('translations/dictionary')) {
        return dictionaryResponse('km', {
          'meeting_requests.calendar_ui.months.oct': 'ខែតុលាពី API',
          'meeting_requests.calendar_ui.weekdays.wed': 'ថ្ងៃពុធពី API',
          'meeting_requests.detail.title': 'Request API title',
          'meeting_requests.meeting_calendar.detail.meeting_detail':
              'Calendar API title',
          'meeting_requests.meeting_calendar.detail.list_of_issues':
              'Calendar issues',
          'meeting_requests.meeting_calendar.detail.issue_detail':
              'Calendar issue detail',
          'meeting_requests.meeting_calendar.detail.issue_document':
              'Calendar issue doc',
        });
      }
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'items': [
              {
                'id': 1,
                'title': 'Test meeting',
                'meetingDate': '2026-10-21T00:00:00Z',
                'issues': [
                  {'id': 5, 'title': 'Calendar issue content'},
                ],
              },
            ],
          },
        }),
        200,
      );
    });
    addTearDown(settings.dispose);
    settings.setModuleType(AppModuleType.privateSector);
    await settings.loadTranslations();
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: Scaffold(body: CalendarTab())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ខែតុលាពី API 2026'), findsOneWidget);
    expect(find.text('ថ្ងៃពុធពី API'), findsWidgets);
    await tester.tap(find.text('Test meeting'));
    await tester.pumpAndSettle();
    expect(find.text('Calendar API title'), findsOneWidget);
    expect(find.text('Request API title'), findsNothing);
    await tester.tap(find.text('Calendar issues'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Calendar issue content'));
    await tester.tap(find.text('Calendar issue content'));
    await tester.pumpAndSettle();
    expect(find.text('Calendar issue detail'), findsOneWidget);
    expect(find.text('Calendar issue doc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'loads the full nested dictionary using the requested language',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/translations/dictionary');
          expect(request.url.queryParameters, {
            'language': 'km',
            'module': 'pswg',
          });
          return dictionaryResponse('km', {
            'wg_issues.title': 'បញ្ហាក្រុមការងារ',
          });
        }),
      );
      addTearDown(api.close);
      expect(await TranslationRepository(api).dictionary(AppLanguage.khmer), {
        'wg_issues.title': 'បញ្ហាក្រុមការងារ',
      });
    },
  );

  test('rejects a dictionary for the wrong language', () async {
    final api = ApiClient(
      client: MockClient((_) async => dictionaryResponse('en', {})),
    );
    addTearDown(api.close);
    await expectLater(
      TranslationRepository(api).dictionary(AppLanguage.khmer),
      throwsFormatException,
    );
  });

  test(
    'login loads labels and language switches revalidate cached dictionaries',
    () async {
      final requested = <String>[];
      final settings = settingsWith((request) async {
        final language = request.url.queryParameters['language']!;
        requested.add(language);
        return dictionaryResponse(language, {
          'dashboard.title': '$language dashboard',
        });
      });
      addTearDown(settings.dispose);
      settings.setCurrentUser(
        const AuthUser(
          id: 1,
          email: 'pswg@example.com',
          name: 'PSWG',
          isActive: true,
          roles: ['pswg'],
        ),
      );
      await settings.loadTranslations();
      expect(settings.translations['dashboard.title'], 'km dashboard');
      settings.setLanguage(AppLanguage.english);
      // The Khmer dictionary must disappear before the English response arrives.
      expect(settings.translations, isEmpty);
      await settings.loadTranslations();
      expect(settings.translations['dashboard.title'], 'en dashboard');
      settings.setLanguage(AppLanguage.khmer);
      await settings.loadTranslations();
      expect(requested, ['km', 'en', 'km']);
      settings.setModuleType(AppModuleType.cdcSection);
      expect(settings.translations, isEmpty);
      settings.setModuleType(AppModuleType.privateSector);
      await settings.loadTranslations();
      expect(settings.translations['dashboard.title'], 'km dashboard');
      settings.clearSession();
      expect(settings.translations, isEmpty);
    },
  );

  test(
    'stale language and logged-out responses cannot replace current labels',
    () async {
      final pending = <String, Completer<http.Response>>{};
      final settings = settingsWith((request) {
        final language = request.url.queryParameters['language']!;
        return (pending[language] = Completer<http.Response>()).future;
      });
      addTearDown(settings.dispose);
      settings.setModuleType(AppModuleType.privateSector);
      final oldRequest = settings.loadTranslations();
      settings.setLanguage(AppLanguage.english);
      final newRequest = settings.loadTranslations();
      await Future<void>.delayed(Duration.zero);
      pending['en']!.complete(
        dictionaryResponse('en', {'dashboard.title': 'New'}),
      );
      await newRequest;
      pending['km']!.complete(
        dictionaryResponse('km', {'dashboard.title': 'Old'}),
      );
      await oldRequest;
      expect(settings.translations['dashboard.title'], 'New');
      settings.setLanguage(AppLanguage.khmer);
      final loggedOutRequest = settings.loadTranslations();
      await Future<void>.delayed(Duration.zero);
      settings.clearSession();
      pending['km']!.complete(
        dictionaryResponse('km', {'dashboard.title': 'Old session'}),
      );
      await loggedOutRequest;
      expect(settings.translations, isEmpty);
    },
  );

  test('failed refresh preserves loaded labels and can be retried', () async {
    var fail = false;
    final settings = settingsWith(
      (_) async => fail
          ? http.Response('{"success":false}', 503)
          : dictionaryResponse('km', {'dashboard.title': 'Server label'}),
    );
    addTearDown(settings.dispose);
    settings.setModuleType(AppModuleType.privateSector);
    await settings.loadTranslations();
    fail = true;
    await settings.loadTranslations(refresh: true);
    expect(settings.translationError, isA<ApiException>());
    expect(settings.translations['dashboard.title'], 'Server label');
    fail = false;
    await settings.loadTranslations(refresh: true);
    expect(settings.translationError, isNull);
  });

  test(
    'page context distinguishes stats, statuses and missing mobile labels',
    () {
      const values = {
        'dashboard_plenary.in_progress': 'Dashboard progress',
        'issue_matrix.stats.in_progress': 'Matrix statistic',
        'issue_matrix.value_labels.in_progress': 'Matrix status',
        'meeting_requests.status.completed': 'Meeting completed',
        'progress_report.values.completed': 'Report reviewed',
        'progress_report.values.re-reviewing': 'Reviewing again',
        'meeting_summary.status.draft': 'Summary draft',
        'meeting_summary.status.solved': 'Wrong meeting status',
        'meeting_summary.issue_dialog.solved': 'Summary issue solved',
        'wg_issues.status.saved': 'Saved issue',
      };
      AppLocalizations page(String page) =>
          AppLocalizations(AppLanguage.khmer, dictionary: values, page: page);
      expect(
        page('dashboard_plenary').text('inProgress'),
        'Dashboard progress',
      );
      expect(page('issue_matrix').text('inProgress'), 'Matrix statistic');
      expect(page('issue_matrix').status('IN_PROGRESS'), 'Matrix status');
      expect(page('meeting_requests').status('COMPLETED'), 'Meeting completed');
      expect(page('progress_report').status('COMPLETED'), 'Report reviewed');
      expect(page('progress_report').status('RE_REVIEWING'), 'Reviewing again');
      expect(page('meeting_summary').status('DRAFT'), 'Summary draft');
      expect(
        page('meeting_summary_issue').status('SOLVED'),
        'Summary issue solved',
      );
      expect(page('wg_issues').status('SAVED'), 'Saved issue');
      expect(page('wg_issues').status('Custom workflow'), 'Custom workflow');
      expect(
        page('wg_issues').text('profile'),
        const AppLocalizations(AppLanguage.khmer).text('profile'),
      );
      expect(
        page('wg_issues').api('missing', fallback: 'Fallback'),
        'Fallback',
      );
    },
  );

  testWidgets(
    'loaded and switched dictionaries rebuild labels and filter status',
    (tester) async {
      final settings = settingsWith((request) async {
        final language = request.url.queryParameters['language']!;
        return dictionaryResponse(language, {
          'dashboard_plenary.total_primary_agencies':
              '$language agencies from API',
          'progress_report.values.completed': '$language report reviewed',
        });
      });
      addTearDown(settings.dispose);
      settings.setModuleType(AppModuleType.privateSector);
      await settings.loadTranslations();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TranslationPageScope(
                    page: 'dashboard_plenary',
                    child: Builder(
                      builder: (context) => Text(
                        AppLocalizations.of(
                          context,
                        ).text('totalPrimaryAgencies'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ApiFilterSheet(
                      translationPage: 'progress_report',
                      initial: FilterSelection(),
                      load: () async => [
                        const FilterSection(
                          id: 'status',
                          title: 'status',
                          options: [
                            FilterOption(
                              value: 'COMPLETED',
                              label: 'Completed',
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
      expect(find.text('km agencies from API'), findsOneWidget);
      expect(find.text('km report reviewed'), findsOneWidget);
      settings.setLanguage(AppLanguage.english);
      await tester.runAsync(() => settings.loadTranslations());
      await tester.pumpAndSettle();
      expect(find.text('en agencies from API'), findsOneWidget);
      expect(find.text('en report reviewed'), findsOneWidget);
      expect(find.text('km agencies from API'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
