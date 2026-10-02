import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_report.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_reports_repository.dart';
import 'package:gpsf_app/screens/report/report_screen.dart';
import 'package:gpsf_app/screens/report/progress_report_detail_loader.dart';
import 'package:gpsf_app/screens/report/report_detail_screen.dart';
import 'package:gpsf_app/screens/report/tabs/report_progress_report_tab.dart';
import 'package:gpsf_app/translations/app_language.dart';

Map<String, dynamic> ministryDetail() => {
  'id': 46,
  'progressReportId': 4,
  'status': 'SUBMITTED',
  'ministry': {'id': 3, 'name': 'MAFF'},
  'progressReport': {
    'id': 4,
    'title': 'Full ministry report',
    'year': 2027,
    'semester': 'S2',
  },
  'ministryInformation': {
    'submittedAt': '2026-09-15T08:00:00Z',
    'preparedBy': {'name': 'Actual ministry preparer'},
    'approvalProgressReport': {'path': '/uploads/approval.pdf'},
  },
  'cdcInformation': {
    'status': 'CDC_UNDER_REVIEW',
    'reviewedBy': {'name': 'Actual CDC reviewer'},
    'latestUpdatedAt': '2026-09-16T08:00:00Z',
    'requestDocument': {'path': '/uploads/request.pdf'},
    'meeting': {'meetingDate': '2026-09-14', 'startTime': '12:00:00'},
  },
  'description': '<p>Actual ministry description</p>',
  'openIssues': [
    {
      'id': 5,
      'title': 'Actual ministry issue',
      'status': 'IN_PROGRESS',
      'category': 'General',
    },
  ],
  'rgcDecisions': [
    {
      'id': 7,
      'decision': 'Actual ministry decision',
      'status': 'NOT_ADDRESSED',
      'category': 'Climate',
    },
  ],
};

http.Response reportResponse(Object data) => http.Response.bytes(
  utf8.encode(jsonEncode({'success': true, 'data': data})),
  200,
);

void main() {
  test(
    'maps complete ministry detail fields instead of top-level list fields',
    () {
      final report = ProgressReport(ministryDetail());
      expect(report.id, 46);
      expect(report.year, 2027);
      expect(report.preparedBy, 'Actual ministry preparer');
      expect(report.reviewedBy, 'Actual CDC reviewer');
      expect(report.submittedAt, DateTime.parse('2026-09-15T08:00:00Z'));
      expect(report.updatedAt, DateTime.parse('2026-09-16T08:00:00Z'));
      expect(report.cdcStatus, 'CDC_UNDER_REVIEW');
      expect(report.approvalDocument, '/uploads/approval.pdf');
      expect(report.requestDocument, '/uploads/request.pdf');
      expect(
        report.attachmentPaths,
        containsAll(['/uploads/approval.pdf', '/uploads/request.pdf']),
      );
      expect(report.latestMeeting['startTime'], '12:00:00');
      final unsent = ProgressReport({
        ...ministryDetail(),
        'cdcInformation': {
          'status': null,
          'latestUpdatedAt': null,
          'meeting': null,
        },
      });
      expect(unsent.cdcStatus, isEmpty);
      expect(unsent.updatedAt, isNull);
      expect(unsent.latestMeeting, isEmpty);
    },
  );

  test(
    'ministry detail validates parent report ID rather than assignment ID',
    () async {
      var valid = true;
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/progress-reports/4/ministries/me');
          return reportResponse({
            ...ministryDetail(),
            'progressReportId': valid ? 4 : 9,
          });
        }),
      );
      addTearDown(api.close);
      final repository = ProgressReportsRepository(api);
      expect(
        (await repository.getDetail(
          4,
          scope: ProgressReportDetailScope.ministry,
        )).id,
        46,
      );
      valid = false;
      await expectLater(
        repository.getDetail(4, scope: ProgressReportDetailScope.ministry),
        throwsA(isA<ApiException>()),
      );
    },
  );

  for (final role in [
    AppModuleType.lineMinistry,
    AppModuleType.privateSector,
  ]) {
    testWidgets(
      '$role View Details fetches complete report instead of list data',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final calls = <String>[];
        final ministry = role == AppModuleType.lineMinistry;
        final endpoint = ministry
            ? '/api/v1/progress-reports/4/ministries/me'
            : '/api/v1/progress-reports/assignments/46';
        final settings =
            AppSettingsController(
                authRepository: AuthRepository(
                  ApiClient(
                    client: MockClient((request) async {
                      calls.add(request.url.path);
                      if (request.url.path == '/api/v1/progress-reports') {
                        return reportResponse([
                          {
                            'id': ministry ? 4 : 46,
                            'title': 'Partial list report',
                            'year': 2027,
                            'semester': 'S2',
                            'status': 'SENT',
                          },
                        ]);
                      }
                      expect(request.url.path, endpoint);
                      return reportResponse(
                        ministry
                            ? ministryDetail()
                            : {
                                'id': 46,
                                'progressReportId': 4,
                                'status': 'SHARED_WITH_PSWG',
                                'ministry': {'name': 'MAFF'},
                                'preparedBy': {
                                  'name': 'Actual ministry preparer',
                                },
                                'reviewedBy': {'name': 'Actual CDC reviewer'},
                                'submittedAt': '2026-09-15T08:00:00Z',
                                'attachment': {'path': '/uploads/approval.pdf'},
                                'progressReport': {
                                  'id': 4,
                                  'title': 'Full ministry report',
                                  'year': 2027,
                                  'semester': 'S2',
                                  'description':
                                      '<p>Actual ministry description</p>',
                                  'requestDocument': {
                                    'path': '/uploads/request.pdf',
                                  },
                                },
                                'openIssues': ministryDetail()['openIssues'],
                                'rgcDecisions':
                                    ministryDetail()['rgcDecisions'],
                              },
                      );
                    }),
                  ),
                ),
              )
              ..setLanguage(AppLanguage.english)
              ..setModuleType(role);
        addTearDown(settings.dispose);
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
        await tester.tap(find.text('View Details'));
        await tester.pumpAndSettle();
        expect(find.byType(ReportDetailScreen), findsOneWidget);
        expect(
          find.textContaining('Actual ministry preparer', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('approval.pdf'), findsOneWidget);
        expect(find.text('request.pdf'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Actual ministry description'),
          150,
        );
        await tester.tap(find.text('All Issues'));
        await tester.pumpAndSettle();
        expect(find.text('Actual ministry issue'), findsOneWidget);
        await tester.tap(find.text('RGC Decision'));
        await tester.pumpAndSettle();
        expect(find.text('Actual ministry decision'), findsOneWidget);
        expect(calls, ['/api/v1/progress-reports', endpoint]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('ministry detail retries its own endpoint after failure', (
    tester,
  ) async {
    var calls = 0;
    final settings =
        AppSettingsController(
            authRepository: AuthRepository(
              ApiClient(
                client: MockClient((request) async {
                  expect(
                    request.url.path,
                    '/api/v1/progress-reports/4/ministries/me',
                  );
                  if (++calls == 1) {
                    return http.Response(
                      jsonEncode({'success': false, 'message': 'Unavailable'}),
                      503,
                    );
                  }
                  return reportResponse(ministryDetail());
                }),
              ),
            ),
          )
          ..setLanguage(AppLanguage.english)
          ..setModuleType(AppModuleType.lineMinistry);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: ProgressReportDetailLoader(id: 4)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Actual ministry preparer', findRichText: true),
      findsOneWidget,
    );
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  test('maps the current top-level progress report response', () {
    final report = ProgressReport({
      'id': 2,
      'title': 'ចំណងជើងរបាយការណ៍ **',
      'year': 2026,
      'semester': 'S2',
      'status': 'SENT',
      'activeDeadline': {'date': '2026-09-15'},
      'meetings': [
        {'meetingDate': '2026-09-03'},
        {'meetingDate': '2026-09-04'},
      ],
      'ministryDocuments': [
        {
          'ministry': {'name': 'MAFF'},
          'document': {'path': '/maff.pdf'},
        },
      ],
      'ministryAssignment': {'issues': 0},
    });
    expect(report.title, 'ចំណងជើងរបាយការណ៍ **');
    expect(report.deadline, DateTime.parse('2026-09-15'));
    expect(report.firstMeeting, DateTime.parse('2026-09-03'));
    expect(report.ministry, 'MAFF');
  });

  for (final role in [
    AppModuleType.privateSector,
    AppModuleType.lineMinistry,
  ]) {
    testWidgets('$role Progress Report uses the shared API', (tester) async {
      final requests = <String>[];
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    requests.add(request.url.path);
                    return http.Response.bytes(
                      utf8.encode(
                        jsonEncode({
                          'success': true,
                          'data': [
                            {
                              'id': 1,
                              'title': 'ចំណងជើងរបាយការណ៍ **',
                              'description': 'ការពិពណ៌នា **',
                              'year': 2026,
                              'semester': 'S2',
                              'status': 'SENT',
                              'activeDeadline': {'date': '2026-09-15'},
                              'deadlines': [
                                {'date': '2026-12-15'},
                                {'date': '2026-09-29'},
                              ],
                              'meetings': [
                                {'meetingDate': '2026-09-03'},
                                {'meetingDate': '2026-09-04'},
                              ],
                              'ministryDocuments': [
                                {
                                  'ministry': {'name': 'MAFF'},
                                  'document': {
                                    'path': '/maff.pdf',
                                    'name': 'MAFF.pdf',
                                  },
                                },
                              ],
                              'finalSemesterReport': {
                                'path': '/final.pdf',
                                'name': 'final.pdf',
                              },
                              'ministryAssignment': {
                                'issues': 3,
                                'attachment': {'path': '/solution.pdf'},
                              },
                            },
                          ],
                        }),
                      ),
                      200,
                    );
                  }),
                ),
              ),
            )
            ..setLanguage(AppLanguage.english)
            ..setModuleType(role);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: Scaffold(body: ReportScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(requests, ['/api/v1/progress-reports']);
      expect(find.text('ចំណងជើងរបាយការណ៍ **'), findsOneWidget);
    });
  }
}
