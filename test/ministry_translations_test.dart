import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/auth/data/auth_user.dart';
import 'package:gpsf_app/features/line_ministry/reports/ministry_rgc_decision_sheet.dart';
import 'package:gpsf_app/features/line_ministry/issues/issue_detail_screen.dart';
import 'package:gpsf_app/features/private_sector/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/features/private_sector/meetings/tabs/calendar_tab.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decision.dart';
import 'package:gpsf_app/screens/report/rgc_decision_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:gpsf_app/translations/ministry_translation_keys.dart';
import 'package:gpsf_app/translations/translation_repository.dart';
import 'package:gpsf_app/translations/translation_sync.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response response(
  String module,
  String language,
  Map<String, String> labels,
) => http.Response(
  jsonEncode({
    'success': true,
    'data': {
      'success': true,
      'data': {
        'module': module,
        'language': language,
        'page': null,
        'translations': labels,
      },
    },
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

AppSettingsController controller(
  Future<http.Response> Function(http.Request) handler,
) => AppSettingsController(
  authRepository: AuthRepository(ApiClient(client: MockClient(handler))),
);

void main() {
  // Captured API labels; calendar issue count added from the supplied km
  // response and the Web English seed.
  final fixtures =
      jsonDecode(
            File(
              'test/fixtures/ministry_translation_labels.json',
            ).readAsStringSync(),
          )
          as Map;
  for (final language in AppLanguage.values) {
    final code = language == AppLanguage.khmer ? 'km' : 'en';
    final labels = Map<String, String>.from(fixtures[code] as Map);
    testWidgets(
      '$code ministry issue description tab refreshes its own label',
      (tester) async {
        var label = 'Ministry detail description';
        final settings = controller(
          (_) async => response('ministry', code, {
            'issue_matrix.submitted_detail.issue_description': label,
            'issue_matrix.column.issue_description': 'Wrong list description',
          }),
        )..setLanguage(language);
        addTearDown(settings.dispose);
        await settings.loadTranslations();
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: const MaterialApp(
              home: LineMinistryIssueDetailScreen(
                title: 'Authored issue',
                category: '',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(label), findsNWidgets(2));
        expect(find.text('Wrong list description'), findsNothing);
        label = 'Updated ministry description';
        await settings.loadTranslations(refresh: true);
        await tester.pumpAndSettle();
        expect(find.text(label), findsNWidgets(2));
        expect(find.text('Ministry detail description'), findsNothing);
        expect(find.text('Authored issue'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    testWidgets('$code ministry calendar uses its own empty label', (
      tester,
    ) async {
      var label = 'Ministry empty calendar';
      final settings = controller((request) async {
        if (request.url.path.endsWith('translations/dictionary')) {
          return response('ministry', code, {
            'meeting_calendar.meeting_calendar.table.empty': label,
            'meeting_requests.meeting_calendar.table.empty':
                'Wrong request empty',
          });
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'items': []},
          }),
          200,
        );
      })..setLanguage(language);
      addTearDown(settings.dispose);
      await settings.loadTranslations();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: CalendarTab(selectedDate: DateTime(2026, 10, 21)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      expect(find.text('Wrong request empty'), findsNothing);
      label = 'Updated ministry empty';
      await settings.loadTranslations(refresh: true);
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      expect(find.text('Ministry empty calendar'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    for (final scope in [0, 1]) {
      testWidgets('$code ministry dashboard scope $scope uses API tab label', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var label = 'Ministry overall status';
        final prefix = scope == 0 ? 'plenary_dashboard' : 'dashboard';
        final settings = controller((request) async {
          if (request.url.path.endsWith('translations/dictionary')) {
            return response('ministry', code, {
              '$prefix.overall_status': label,
              'dashboard_plenary.overall_status': 'Wrong PSWG label',
              'dashboard_working_group.overall_status': 'Wrong PSWG label',
            });
          }
          return http.Response(
            File(
              scope == 0
                  ? 'test/fixtures/plenary.json'
                  : 'test/fixtures/working_groups.json',
            ).readAsStringSync(),
            200,
          );
        })..setLanguage(language);
        addTearDown(settings.dispose);
        await settings.loadTranslations();
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: Scaffold(body: DashboardPage(initialScopeTab: scope)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(label), findsNWidgets(2));
        expect(find.text('Wrong PSWG label'), findsNothing);
        label = 'Updated ministry overall';
        await settings.loadTranslations(refresh: true);
        await tester.pumpAndSettle();
        expect(find.text(label), findsNWidgets(2));
        expect(find.text('Ministry overall status'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
    test(
      '$code calendar issue count stays separate from request issue count',
      () {
        final l10n = AppLocalizations(
          language,
          module: AppModuleType.lineMinistry,
          page: 'meeting_calendar',
          dictionary: {
            'meeting_calendar.meeting_calendar.table.issue_count':
                'Calendar count',
            'meeting_calendar.table.issues': 'Wrong request count',
          },
        );
        expect(l10n.text('totalIssues'), 'Calendar count');
      },
    );

    testWidgets(
      '$code ministry RGC report uses and refreshes ministry labels',
      (tester) async {
        var revision = 'initial';
        final reportLabels = {
          'plenary_rgc_decisions.rgc.date_of_issue_solution': 'solution date',
          'plenary_rgc_decisions.rgc.indicators': 'indicators',
          'plenary_rgc_decisions.rgc.implementation_challenges': 'challenges',
          'plenary_rgc_decisions.rgc.request': 'requests',
          'plenary_rgc_decisions.rgc.progress_solution': 'progress',
          'plenary_rgc_decisions.rgc.rgc_decision': 'decision',
        };
        final settings = controller((request) async {
          expect(request.url.queryParameters['module'], 'ministry');
          return response('ministry', code, {
            ...labels,
            for (final entry in reportLabels.entries)
              entry.key: '$revision $code ${entry.value}',
            'issue_matrix_rgc_decision.rgc.report.progressSolution':
                'Wrong CDC',
          });
        })..setLanguage(language);
        addTearDown(settings.dispose);
        await settings.loadTranslations();
        final data =
            jsonDecode(
                  File(
                    'test/fixtures/ministry_rgc_decision.json',
                  ).readAsStringSync(),
                )['data']
                as Map<String, dynamic>;
        final detail = RgcDecisionDetail.fromJson({
          ...data,
          'progressReports': [
            {
              'semester': 'S1',
              'year': 2028,
              'dateOfIssueSolution': '2026-10-19',
              'referenceName': 'Reference content',
              'progressSolution': 'Progress content',
            },
          ],
        });
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RgcDecisionProgressReports(detail: detail),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in reportLabels.values) {
          expect(
            find.textContaining('$revision $code $label', findRichText: true),
            findsOneWidget,
          );
        }
        expect(find.text('Wrong CDC'), findsNothing);
        revision = 'updated';
        await settings.loadTranslations(refresh: true);
        await tester.pumpAndSettle();
        for (final label in reportLabels.values) {
          expect(
            find.textContaining('$revision $code $label', findRichText: true),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    test('$code ministry aliases exist in the reference dictionary', () {
      final keys = {
        ...ministryCommonKeys.values,
        ...ministryPageKeys.values.expand((map) => map.values),
        ...ministryFilterKeys.values.expand((map) => map.values),
      };
      for (final key in keys) {
        expect(labels[key], isNotNull, reason: key);
      }
      AppLocalizations page(String name) => AppLocalizations(
        language,
        module: AppModuleType.lineMinistry,
        dictionary: labels,
        page: name,
      );
      expect(
        page(
          'progress_report',
        ).api('progress_report.shared.decisions.title', fallback: 'fallback'),
        labels['progress_reports.shared.decisions.title'],
      );
      expect(
        page('plenary_rgc_decisions').text('linkedIssues'),
        labels['plenary_rgc_decisions.rgc.linked_issues'],
      );
      expect(
        page('meeting_calendar').text('filters'),
        labels['meeting_calendar.filter_panel.filters'],
      );
      expect(
        page('meeting_calendar').text('meetingRequests'),
        labels['meeting_requests.title'],
        reason: 'Calendar inheritance must not rename the Requests tab',
      );
      expect(
        page('meeting_calendar').status('SCHEDULED'),
        labels['meeting_calendar.status_labels.scheduled'],
      );
      expect(
        page('meeting_summary').status('SUBMITTED'),
        labels['meeting_summary.status_labels.submitted'],
      );
      for (final entry in {
        'summaryReferenceDocument': 'summary_reference',
        'meetingDocument': 'meeting_document',
        'sentBy': 'sent_by',
      }.entries) {
        expect(
          page('meeting_summary').text(entry.key),
          labels['meeting_summary.details.${entry.value}'],
        );
      }
    });
    test(
      '$code repository fetches and validates the ministry envelope',
      () async {
        final repository = TranslationRepository(
          ApiClient(
            client: MockClient((request) async {
              expect(request.url.queryParameters, {
                'language': code,
                'module': 'ministry',
              });
              expect(request.headers['Cache-Control'], 'no-cache, no-store');
              return response('ministry', code, labels);
            }),
          ),
        );
        expect(
          await repository.dictionary(language, module: 'ministry'),
          labels,
        );
      },
    );
  }

  test(
    'module and language changes discard stale responses and isolate caches',
    () async {
      final pending = <String, Completer<http.Response>>{};
      final settings = controller((request) {
        final query = request.url.queryParameters;
        final key = '${query['module']}/${query['language']}';
        return (pending[key] = Completer<http.Response>()).future;
      });
      addTearDown(settings.dispose);
      final old = settings.loadTranslations();
      await Future<void>.delayed(Duration.zero);
      settings.setModuleType(AppModuleType.privateSector);
      final pswg = settings.loadTranslations();
      await Future<void>.delayed(Duration.zero);
      pending['pswg/km']!.complete(
        response('pswg', 'km', {'dashboard.title': 'PSWG'}),
      );
      await pswg;
      pending['ministry/km']!.complete(
        response('ministry', 'km', {'dashboard.title': 'Stale ministry'}),
      );
      await old;
      expect(settings.translations['dashboard.title'], 'PSWG');
      settings.setModuleType(AppModuleType.lineMinistry);
      expect(settings.translations, isEmpty);
      final ministryKm = settings.loadTranslations();
      await Future<void>.delayed(Duration.zero);
      settings.setLanguage(AppLanguage.english);
      final ministryEn = settings.loadTranslations();
      await Future<void>.delayed(Duration.zero);
      pending['ministry/en']!.complete(
        response('ministry', 'en', {'dashboard.title': 'Ministry EN'}),
      );
      await ministryEn;
      pending['ministry/km']!.complete(
        response('ministry', 'km', {'dashboard.title': 'Stale Khmer'}),
      );
      await ministryKm;
      expect(settings.translations['dashboard.title'], 'Ministry EN');
      settings.setModuleType(AppModuleType.privateSector);
      settings.setLanguage(AppLanguage.khmer);
      expect(settings.translations['dashboard.title'], 'PSWG');
    },
  );

  test(
    'rejects another module dictionary instead of showing incorrect labels',
    () async {
      final repository = TranslationRepository(
        ApiClient(
          client: MockClient(
            (_) async =>
                response('pswg', 'km', {'dashboard.title': 'Wrong module'}),
          ),
        ),
      );
      await expectLater(
        repository.dictionary(AppLanguage.khmer, module: 'ministry'),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'ministry decision sheet refreshes web labels and status without reopening',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.view.physicalSize = const Size(600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var title = 'Web ministry detail';
      var fail = false;
      final settings = controller((request) async {
        expect(request.url.queryParameters['module'], 'ministry');
        return fail
            ? http.Response('{"success": false}', 503)
            : response('ministry', 'km', {
                'plenary_rgc_decisions.rgc.detail_title': title,
                'plenary_rgc_decisions.rgc.not_addressed':
                    'Web ministry status',
                'plenary_rgc_decisions.rgc.focal_person': 'Web focal person',
              });
      });
      addTearDown(settings.dispose);
      settings.setCurrentUser(
        const AuthUser(
          id: 1,
          email: 'ministry@example.com',
          name: 'Ministry',
          isActive: true,
          roles: ['line_ministry'],
        ),
      );
      await settings.loadTranslations();
      final data =
          jsonDecode(
                File(
                  'test/fixtures/ministry_rgc_decision.json',
                ).readAsStringSync(),
              )['data']
              as Map<String, dynamic>;
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: TranslationSync(
            controller: settings,
            child: MaterialApp(
              home: Scaffold(
                body: MinistryRgcDecisionSheet(
                  decisionId: 3,
                  detail: RgcDecisionDetail.fromJson(data),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(find.text('• Web ministry status'), findsOneWidget);
      expect(find.text('Web focal person'), findsOneWidget);
      title = 'Edited ministry label';
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(find.text('Web ministry detail'), findsNothing);
      fail = true;
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
