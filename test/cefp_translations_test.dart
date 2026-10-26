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
import 'package:gpsf_app/features/cefp/issues/cdc_issues_matrix_screen.dart';
import 'package:gpsf_app/features/cefp/reports/reports_screen.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decision.dart';
import 'package:gpsf_app/screens/report/rgc_decision_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:gpsf_app/translations/cefp_translation_keys.dart';
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
  String code,
  Map<String, String> labels,
) => ok({
  'success': true,
  'data': {
    'module': module,
    'language': code,
    'page': null,
    'translations': labels,
  },
});
AppSettingsController settingsWith(
  Future<http.Response> Function(http.Request) handler,
) => AppSettingsController(
  authRepository: AuthRepository(ApiClient(client: MockClient(handler))),
)..setModuleType(AppModuleType.cefp);

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/cefp_translation_labels.json',
            ).readAsStringSync(),
          )
          as Map;
  for (final language in AppLanguage.values) {
    final code = language == AppLanguage.khmer ? 'km' : 'en';
    final labels = Map<String, String>.from(fixture[code] as Map);
    test(
      '$code CEFP aliases exist in live API and preserve page namespaces',
      () {
        for (final key in {
          ...cefpCommonKeys.values,
          ...cefpPageKeys.values.expand((m) => m.values),
          ...cefpFilterKeys.values.expand((m) => m.values),
        }) {
          expect(labels[key], isNotNull, reason: key);
        }
        AppLocalizations page(String name) => AppLocalizations(
          language,
          module: AppModuleType.cefp,
          page: name,
          dictionary: labels,
        );
        expect(
          page('cdc_issue_matrix').text('categories'),
          labels['cefp_issue_matrix.column.category'],
        );
        expect(
          page('issue_matrix').text('categories'),
          labels['issue_matrix.column.issue_category'],
        );
        expect(
          page('cdc_issue_detail').status('NEW_SUBMISSION'),
          labels['cefp_issue_matrix.status.new_submission'],
        );
        expect(
          page('cdc_issue_detail').status('SAVED'),
          labels['cefp_issue_matrix.status.saved'],
        );
        expect(
          AppLocalizations(
            language,
            module: AppModuleType.cefp,
          ).status('SAVED'),
          labels['cefp_issue_matrix.status.saved'],
        );
        expect(
          page('issue_matrix_detail').status('SOLVED'),
          labels['issue_matrix.value_labels.solved'],
        );
        expect(
          page('cdc_rgc_detail').status('IN_PROGRESS'),
          labels['rgc_decision.status.in_progress'],
        );
        expect(
          page('cdc_rgc_report').api(
            'issue_matrix_rgc_decision.rgc.report.tab',
            fallback: 'missing',
          ),
          labels['rgc_decision.report.tab'],
        );
        expect(
          page('dashboard_working_group').text('totalIssues'),
          labels['dashboard_working_group.total_issues'],
        );
        expect(
          page('dashboard_plenary').text('totalIssues'),
          labels['dashboard_plenary.total_issues'],
        );
      },
    );
    test(
      '$code CEFP repository fetches its own dictionary with no cache',
      () async {
        final client = ApiClient(
          client: MockClient((request) async {
            expect(request.url.queryParameters, {
              'language': code,
              'module': 'cefp',
            });
            expect(request.headers['Cache-Control'], 'no-cache, no-store');
            return dictionary('cefp', code, labels);
          }),
        );
        addTearDown(client.close);
        expect(
          await TranslationRepository(
            client,
          ).dictionary(language, module: 'cefp'),
          labels,
        );
      },
    );
    testWidgets('$code CEFP RGC list, filter and report use CEFP API keys', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = settingsWith((request) async {
        if (request.url.path.endsWith('translations/dictionary')) {
          return dictionary('cefp', code, {
            ...labels,
            'rgc_decision.table.focal_person': 'CEFP focal $code',
            'rgc_decision.filter_panel.filter': 'CEFP filter $code',
            'rgc_decision.filter_panel.filters': 'CEFP filters $code',
            'rgc_decision.report.tab': 'CEFP {semester} / {year}',
            'rgc_decision.report.referenceName': 'CEFP reference $code',
            'issue_matrix_rgc_decision.rgc.report.referenceName':
                'Wrong module',
          });
        }
        if (request.url.path.endsWith('filter-options')) {
          return ok({
            'categories': [],
            'statuses': [],
            'governmentAgencies': [],
          });
        }
        return ok({
          'items': [
            {
              'id': 3,
              'decision': 'API decision',
              'focalPerson': 'Actual person',
              'status': 'IN_PROGRESS',
            },
          ],
        });
      })..setLanguage(language);
      addTearDown(settings.dispose);
      await settings.loadTranslations();
      Widget app(Widget body) => AppSettings(
        controller: settings,
        child: MaterialApp(home: Scaffold(body: body)),
      );
      await tester.pumpWidget(app(const CefpReportsScreenView()));
      await tester.pumpAndSettle();
      expect(find.text('CEFP focal $code'), findsOneWidget);
      await tester.tap(find.text('CEFP filter $code'));
      await tester.pumpAndSettle();
      expect(find.byType(ApiFilterSheet), findsOneWidget);
      expect(find.text('CEFP filters $code'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      final detail = RgcDecisionDetail.fromJson({
        'id': 3,
        'progressReports': [
          {'semester': 'S1', 'year': 2028, 'referenceName': 'Actual reference'},
        ],
      });
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            child: RgcDecisionProgressReports(detail: detail),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizations(language).number('CEFP S1 / 2028')),
        findsOneWidget,
      );
      expect(find.text('CEFP reference $code'), findsOneWidget);
      expect(find.text('Wrong module'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'CEFP matrix refreshes labels in foreground and preserves them on failure',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.view.physicalSize = const Size(600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var total = 'CEFP API total';
      var fail = false;
      final settings = settingsWith((request) async {
        if (request.url.path.endsWith('translations/dictionary')) {
          expect(request.url.queryParameters['module'], 'cefp');
          return fail
              ? http.Response('{}', 503)
              : dictionary('cefp', 'km', {
                  'cefp_issue_matrix.title': 'CEFP matrix API',
                  'cefp_issue_matrix.stats.total_issues': total,
                  'cefp_issue_matrix.filter_panel.filter': 'CEFP filter API',
                  'cefp_issue_matrix.filter_panel.filters':
                      'CEFP filter heading API',
                  'issue_matrix.stats.total_issues': 'Wrong general matrix',
                });
        }
        if (request.url.path.endsWith('filter-options')) {
          return ok({'categories': [], 'statuses': [], 'workingGroups': []});
        }
        if (request.url.path.endsWith('/summary')) {
          return ok({
            'totalIssues': 0,
            'solved': 0,
            'inProgress': 0,
            'notAddressed': 0,
            'totalPrimaryAgencies': 0,
          });
        }
        return ok({'items': []});
      });
      addTearDown(settings.dispose);
      settings.setCurrentUser(
        const AuthUser(
          id: 1,
          email: 'cdc@example.com',
          name: 'CEFP',
          isActive: true,
          roles: ['cefp'],
        ),
      );
      await settings.loadTranslations();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: TranslationSync(
            controller: settings,
            child: const MaterialApp(
              home: Scaffold(body: CefpIssuesMatrixScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CEFP matrix API'), findsOneWidget);
      expect(find.text(total), findsOneWidget);
      expect(find.text('Wrong general matrix'), findsNothing);
      total = 'Edited on CEFP web';
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(find.text(total), findsOneWidget);
      fail = true;
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(find.text(total), findsOneWidget);
      await tester.tap(find.text('CEFP filter API'));
      await tester.pumpAndSettle();
      expect(find.text('CEFP filter heading API'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'late CEFP response cannot overwrite CDC and caches stay separate',
    () async {
      final pending = Completer<http.Response>();
      final settings = settingsWith((request) async {
        final module = request.url.queryParameters['module']!;
        if (module == 'cefp') return pending.future;
        return dictionary('cdc', 'km', {'dashboard.title': 'CDC only'});
      });
      addTearDown(settings.dispose);
      final old = settings.loadTranslations();
      await Future<void>.delayed(Duration.zero);
      settings.setModuleType(AppModuleType.cdcSection);
      await settings.loadTranslations();
      pending.complete(
        dictionary('cefp', 'km', {'dashboard.title': 'Stale CEFP'}),
      );
      await old;
      expect(settings.translations['dashboard.title'], 'CDC only');
      settings.setModuleType(AppModuleType.cefp);
      expect(settings.translations, isEmpty);
    },
  );
}
