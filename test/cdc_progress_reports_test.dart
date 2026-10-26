import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_reports_repository.dart';
import 'package:gpsf_app/screens/report/report_screen.dart';
import 'package:gpsf_app/screens/report/report_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';

http.Response ok(Object data, {int pages = 1}) => http.Response(
  jsonEncode({
    'success': true,
    'data': data,
    'meta': {'totalPages': pages},
  }),
  200,
);

void main() {
  for (final language in [AppLanguage.english, AppLanguage.khmer]) {
    testWidgets(
      'CDC GPSF progress reports precede Dashboard and load ministry details: $language',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final paths = <String>[];
        final settings = AppSettingsController(
          authRepository: AuthRepository(
            ApiClient(
              client: MockClient((request) async {
                paths.add(request.url.path);
                final page = request.url.queryParameters['page'];
                switch (request.url.path) {
                  case '/api/v1/progress-reports':
                    expect(request.url.queryParameters['limit'], '100');
                    return ok([
                      {
                        'id': page == '1' ? 4 : 5,
                        'title': page == '1' ? 'Semester 2' : 'Semester 1',
                        'year': 2026,
                        'semester': page == '1' ? 'S2' : 'S1',
                        'status': 'SENT',
                        'activeDeadline': {'date': '2026-10-30'},
                        'meetings': [
                          {'meetingDate': '2026-06-07'},
                          {'meetingDate': '2026-08-20'},
                        ],
                        'deadlines': [
                          {'date': '2026-04-30'},
                          {'date': '2026-06-30'},
                        ],
                      },
                    ], pages: 2);
                  case '/api/v1/progress-reports/4':
                    return ok({
                      'id': 4,
                      'title': 'Full CDC report',
                      'description': 'CDC API description',
                      'year': 2026,
                      'semester': 'S2',
                      'status': 'SENT',
                    });
                  case '/api/v1/progress-reports/4/ministries':
                    return ok([
                      {
                        'id': page == '1' ? 46 : 47,
                        'ministryId': page == '1' ? 3 : 9,
                        'ministry': {'name': page == '1' ? 'MAFF' : 'MEF'},
                        'issues': 3,
                        'status': 'CDC_UNDER_REVIEW',
                      },
                    ], pages: 2);
                  case '/api/v1/progress-reports/4/ministries/3':
                    return ok({
                      'id': 46,
                      'progressReportId': 4,
                      'ministryId': request.url.path.endsWith('/9') ? 9 : 3,
                      'ministry': {
                        'name': request.url.path.endsWith('/9')
                            ? 'MEF'
                            : 'MAFF',
                      },
                      'progressReport': {
                        'title': 'Full report',
                        'year': 2026,
                        'semester': 'S2',
                      },
                      'ministryInformation': {
                        'submittedAt': '2026-10-19',
                        'preparedBy': {'name': 'Actual preparer'},
                        'approvalProgressReport': {
                          'path': '/report.pdf',
                          'originalName': 'MAFF approval.pdf',
                        },
                      },
                      'cdcInformation': {
                        'status': 'CDC_UNDER_REVIEW',
                        'reviewedBy': {'name': 'Actual reviewer'},
                      },
                      'description': 'Actual description',
                      'openIssues': [],
                      'rgcDecisions': [],
                    });
                  default:
                    throw StateError('Unexpected API: ${request.url}');
                }
              }),
            ),
          ),
        );
        settings.setModuleType(AppModuleType.cdcSecretariat);
        settings.setLanguage(language);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: const MaterialApp(home: Scaffold(body: ReportScreen())),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(ReportScreen));
        final l10n = AppLocalizations.of(context);
        final progressTab = find.text(l10n.text('progressReport')).last;
        expect(
          tester.getCenter(progressTab).dx,
          lessThan(tester.getCenter(find.text(l10n.text('dashboard'))).dx),
        );
        final tabStrip = find.byKey(const ValueKey('cdc-report-tabs'));
        expect(
          find.descendant(of: tabStrip, matching: find.byType(FittedBox)),
          findsNothing,
        );
        final tabText = tester.widget<Text>(progressTab);
        expect(tabText.style?.fontSize, 14);
        await tester.drag(tabStrip, const Offset(-500, 0));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(l10n.text('rgcDecision')));
        await tester.pumpAndSettle();
        expect(
          find.text(l10n.text('rgcDecision')).hitTestable(),
          findsOneWidget,
        );
        await tester.ensureVisible(progressTab);
        await tester.pumpAndSettle();
        expect(find.text('Semester 2'), findsOneWidget);
        expect(find.text('Semester 1'), findsOneWidget);
        expect(find.textContaining(l10n.number(2026)), findsWidgets);
        await tester.tap(find.text(l10n.text('viewDetails')).first);
        await tester.pumpAndSettle();
        expect(find.text('Full CDC report'), findsOneWidget);
        expect(find.text('CDC API description'), findsOneWidget);
        expect(find.text('MAFF'), findsOneWidget);
        expect(find.text('MEF'), findsOneWidget);
        for (final selectedLanguage in [
          AppLanguage.khmer,
          AppLanguage.english,
          language,
        ]) {
          settings.setLanguage(selectedLanguage);
          await tester.pumpAndSettle();
          final current = AppLocalizations.of(
            tester.element(find.text('MAFF')),
          );
          expect(
            find.text(
              '${current.text('governmentAgency')} (${current.number(2)})',
            ),
            findsOneWidget,
          );
          expect(
            find.text('${current.text('allIssues')}: ${current.number(3)}'),
            findsNWidgets(2),
          );
        }
        await tester.tap(find.text(l10n.text('viewDetails')).first);
        await tester.pumpAndSettle();
        expect(find.byType(ReportDetailScreen), findsOneWidget);
        expect(
          find.textContaining('Actual preparer', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('Actual reviewer', findRichText: true),
          findsWidgets,
        );
        expect(find.text('MAFF approval.pdf'), findsOneWidget);
        expect(paths, [
          '/api/v1/progress-reports',
          '/api/v1/progress-reports',
          '/api/v1/progress-reports/4',
          '/api/v1/progress-reports/4/ministries',
          '/api/v1/progress-reports/4/ministries',
          '/api/v1/progress-reports/4/ministries/3',
        ]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'CDC progress filter sends API query and keeps plenary tab correct',
    (tester) async {
      final queries = <Map<String, String>>[];
      final api = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/plenaries') {
            expect(request.url.queryParameters['year'], isNull);
            return ok({
              'items': [],
              'meta': {'totalPages': 0},
            });
          }
          expect(request.url.path, '/api/v1/progress-reports');
          queries.add(request.url.queryParameters);
          return ok([
            {
              'id': 4,
              'title': 'Filtered report',
              'year': 2027,
              'semester': 'S2',
              'status': 'SENT',
            },
          ]);
        }),
      );
      final settings =
          AppSettingsController(authRepository: AuthRepository(api))
            ..setModuleType(AppModuleType.cdcSecretariat)
            ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: Scaffold(body: ReportScreen())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2027'));
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      expect(queries.last['year'], '2027');
      expect(find.text('Filter (1)'), findsOneWidget);
      await tester.ensureVisible(find.text('Plenaries'));
      await tester.tap(find.text('Plenaries'));
      await tester.pumpAndSettle();
      expect(find.text('No plenaries found.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'CDC detail rejects a response for another report or ministry',
    () async {
      final api = ApiClient(
        client: MockClient(
          (request) async =>
              ok({'id': 46, 'progressReportId': 9, 'ministryId': 3}),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        ProgressReportsRepository(api).getMinistryDetail(4, 3),
        throwsA(isA<ApiException>()),
      );
    },
  );

  testWidgets('CDC progress report list retries and shows real empty results', (
    tester,
  ) async {
    var calls = 0;
    final settings =
        AppSettingsController(
            authRepository: AuthRepository(
              ApiClient(
                client: MockClient((request) async {
                  expect(request.url.path, '/api/v1/progress-reports');
                  if (++calls == 1) return http.Response('{}', 503);
                  return ok([]);
                }),
              ),
            ),
          )
          ..setModuleType(AppModuleType.cdcSecretariat)
          ..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: Scaffold(body: ReportScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No progress reports found.'), findsOneWidget);
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });
}
