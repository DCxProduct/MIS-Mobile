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
import 'package:gpsf_app/features/cdc_section/issues/cdc_issues_matrix_screen.dart';
import 'package:gpsf_app/features/cdc_section/reports/reports_screen.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decision.dart';
import 'package:gpsf_app/screens/report/rgc_decision_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:gpsf_app/translations/cdc_translation_keys.dart';
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
)..setModuleType(AppModuleType.cdcSection);

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/cdc_translation_labels.json',
            ).readAsStringSync(),
          )
          as Map;
  for (final language in AppLanguage.values) {
    final code = language == AppLanguage.khmer ? 'km' : 'en';
    final labels = Map<String, String>.from(fixture[code] as Map);
    test(
      '$code CDC aliases exist in live API and preserve page namespaces',
      () {
        for (final key in {
          ...cdcCommonKeys.values,
          ...cdcPageKeys.values.expand((m) => m.values),
          ...cdcFilterKeys.values.expand((m) => m.values),
        }) {
          expect(labels[key], isNotNull, reason: key);
        }
        AppLocalizations page(String name) => AppLocalizations(
          language,
          module: AppModuleType.cdcSection,
          page: name,
          dictionary: labels,
        );
        expect(
          page('cdc_issue_matrix').text('categories'),
          labels['cdc_issue_matrix.column.category'],
        );
        expect(
          page('issue_matrix').text('categories'),
          labels['issue_matrix.column.issue_category'],
        );
        expect(
          page('cdc_issue_detail').status('NEW_SUBMISSION'),
          labels['cdc_issue_matrix.status.new_submission'],
        );
        expect(
          page('cdc_issue_detail').status('SAVED'),
          labels['cdc_issue_matrix.status.saved'],
        );
        expect(
          AppLocalizations(
            language,
            module: AppModuleType.cdcSection,
          ).status('SAVED'),
          labels['cdc_issue_matrix.status.saved'],
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
      '$code CDC repository fetches its own dictionary with no cache',
      () async {
        final client = ApiClient(
          client: MockClient((request) async {
            expect(request.url.queryParameters, {
              'language': code,
              'module': 'cdc',
            });
            expect(request.headers['Cache-Control'], 'no-cache, no-store');
            return dictionary('cdc', code, labels);
          }),
        );
        addTearDown(client.close);
        expect(
          await TranslationRepository(
            client,
          ).dictionary(language, module: 'cdc'),
          labels,
        );
      },
    );
    testWidgets('$code CDC RGC list, filter and report use CDC API keys', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = settingsWith((request) async {
        if (request.url.path.endsWith('translations/dictionary')) {
          return dictionary('cdc', code, {
            ...labels,
            'rgc_decision.table.focal_person': 'CDC focal $code',
            'rgc_decision.filter_panel.filter': 'CDC filter $code',
            'rgc_decision.filter_panel.filters': 'CDC filters $code',
            'rgc_decision.report.tab': 'CDC {semester} / {year}',
            'rgc_decision.report.referenceName': 'CDC reference $code',
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
      await tester.pumpWidget(app(const CdcSectionReportsScreenView()));
      await tester.pumpAndSettle();
      expect(find.text('CDC focal $code'), findsOneWidget);
      await tester.tap(find.text('CDC filter $code'));
      await tester.pumpAndSettle();
      expect(find.byType(ApiFilterSheet), findsOneWidget);
      expect(find.text('CDC filters $code'), findsOneWidget);
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
      expect(find.text('CDC S1 / 2028'), findsOneWidget);
      expect(find.text('CDC reference $code'), findsOneWidget);
      expect(find.text('Wrong module'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'CDC matrix refreshes labels in foreground and preserves them on failure',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.view.physicalSize = const Size(600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var total = 'CDC API total';
      var fail = false;
      final settings = settingsWith((request) async {
        if (request.url.path.endsWith('translations/dictionary')) {
          expect(request.url.queryParameters['module'], 'cdc');
          return fail
              ? http.Response('{}', 503)
              : dictionary('cdc', 'km', {
                  'cdc_issue_matrix.title': 'CDC matrix API',
                  'cdc_issue_matrix.stats.total_issues': total,
                  'cdc_issue_matrix.filter_panel.filter': 'CDC filter API',
                  'cdc_issue_matrix.filter_panel.filters':
                      'CDC filter heading API',
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
          name: 'CDC',
          isActive: true,
          roles: ['cdc'],
        ),
      );
      await settings.loadTranslations();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: TranslationSync(
            controller: settings,
            child: const MaterialApp(
              home: Scaffold(body: CdcSectionIssuesMatrixScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CDC matrix API'), findsOneWidget);
      expect(find.text(total), findsOneWidget);
      expect(find.text('Wrong general matrix'), findsNothing);
      total = 'Edited on CDC web';
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(find.text(total), findsOneWidget);
      fail = true;
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(find.text(total), findsOneWidget);
      await tester.tap(find.text('CDC filter API'));
      await tester.pumpAndSettle();
      expect(find.text('CDC filter heading API'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'late CDC response cannot overwrite CDC G-PSF and caches stay separate',
    () async {
      final pending = Completer<http.Response>();
      final settings = settingsWith((request) async {
        final module = request.url.queryParameters['module']!;
        if (module == 'cdc') return pending.future;
        return dictionary('cdcgpsf', 'km', {
          'dashboard.title': 'CDC GPSF only',
        });
      });
      addTearDown(settings.dispose);
      final old = settings.loadTranslations();
      await Future<void>.delayed(Duration.zero);
      settings.setModuleType(AppModuleType.cdcSecretariat);
      await settings.loadTranslations();
      pending.complete(
        dictionary('cdc', 'km', {'dashboard.title': 'Stale CDC'}),
      );
      await old;
      expect(settings.translations['dashboard.title'], 'CDC GPSF only');
      settings.setModuleType(AppModuleType.cdcSection);
      expect(settings.translations, isEmpty);
    },
  );
}
