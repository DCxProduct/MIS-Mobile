import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/cdc_section/issues/issue_detail_screen.dart';
import 'package:gpsf_app/features/cdc_section/issues/issue_detail_loader.dart';
import 'package:gpsf_app/features/cdc_section/issues/issues_screen.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/features/shared/issues/data/issues_repository.dart';
import 'package:gpsf_app/features/shared/issues/data/working_group_issue.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  WorkingGroupIssue sampleApiIssue() => WorkingGroupIssue.fromJson({
    'id': 1,
    'title': 'Climate Issue',
    'issueStatus': {'code': 'SOLVED', 'name': 'Complete'},
    'progressReports': [
      {
        'progressReportId': 12,
        'year': 2025,
        'semester': 'S1',
        'dateOfIssueSolution': '2025-10-30T14:00:00.000Z',
        'sourceOfVerification': '<p>Verification details from API</p>',
        'linkToVerificationSource': 'https://example.com/verification',
        'progressSolution': '<p>Solution from API</p>',
        'indicators': 'Indicators from API',
        'implementationChallenges': 'Challenges from API',
        'requests': 'Requests from API',
        'rgcDecision': 'RGC decision from API',
        'attachment': {
          'name': 'Request Doc',
          'path': '/uploads/documents/request-doc.pdf',
          'size': 204800,
          'mimeType': 'application/pdf',
        },
      },
    ],
  });

  test(
    'supplied working-group issue JSON maps every progress report field',
    () {
      final report = sampleApiIssue().progressReports.single;
      expect(report.title, 'Report S1 2025');
      expect(report.implementationDate, DateTime.utc(2025, 10, 30, 14));
      expect(report.progressReportId, 12);
      expect(report.referenceName, 'Verification details from API');
      expect(report.sourceOfVerification, 'Verification details from API');
      expect(report.description, 'Solution from API');
      expect(report.indicators, 'Indicators from API');
      expect(report.implementationChallenges, 'Challenges from API');
      expect(report.requests, 'Requests from API');
      expect(report.rgcDecision, 'RGC decision from API');
      expect(report.verificationLink, 'https://example.com/verification');
      expect(report.attachmentPaths, ['/uploads/documents/request-doc.pdf']);
      expect(report.attachmentName, 'Request Doc');
      expect(report.attachmentSize, 204800);
    },
  );

  test(
    'working-group detail GET delivers its embedded report to the app',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/working-group-issues/1');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'success': true,
                'data': {
                  'id': 1,
                  'title': 'Climate Issue',
                  'progressReports': [
                    {
                      'progressReportId': 12,
                      'year': 2025,
                      'semester': 'S1',
                      'dateOfIssueSolution': '2025-10-30T14:00:00.000Z',
                      'sourceOfVerification':
                          '<p>Verification details from API</p>',
                      'attachment': {
                        'path': '/uploads/documents/request-doc.pdf',
                        'name': 'Request Doc',
                        'size': 204800,
                      },
                    },
                  ],
                },
              }),
            ),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final issue = await IssuesRepository(api).getIssue(1);
      expect(issue.progressReports.single.title, 'Report S1 2025');
      expect(
        issue.progressReports.single.referenceName,
        'Verification details from API',
      );
      expect(
        issue.progressReports.single.sourceOfVerification,
        'Verification details from API',
      );
      expect(issue.progressReports.single.attachmentName, 'Request Doc');
    },
  );

  test('single linked report uses the issue system reference name', () {
    final issue = WorkingGroupIssue.fromJson({
      'id': 10,
      'title': 'Market issue',
      'sourceOfVerification': '<p>Reference name from system</p>',
      'progressReports': [
        {'progressReportId': 2, 'year': 2026, 'semester': 'S2'},
      ],
    });

    expect(
      issue.progressReports.single.referenceName,
      'Reference name from system',
    );
  });

  testWidgets('CDC Issues opens the selected working-group issue report', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requestedDetails = <String>[];
    final api = ApiClient(
      client: MockClient((request) async {
        final path = request.url.path;
        Object data;
        if (path == '/api/v1/working-group-issues/issue-matrix/summary') {
          data = {
            'totalIssues': 2,
            'solved': 0,
            'inProgress': 2,
            'notAddressed': 0,
            'totalPrimaryAgencies': 1,
          };
        } else if (path == '/api/v1/working-group-issues/issue-matrix') {
          data = {
            'items': [
              {
                'id': 2,
                'title': 'General issue',
                'category': {'name': 'General'},
                'issueStatus': {'code': 'IN_PROGRESS'},
              },
              {
                'id': 1,
                'title': 'Market issue',
                'category': {'name': 'Market Access'},
                'issueStatus': {'code': 'IN_PROGRESS'},
              },
            ],
            'meta': {'totalPages': 1},
          };
        } else {
          requestedDetails.add(path);
          expect(path, '/api/v1/working-group-issues/1');
          data = {
            'id': 1,
            'title': 'Market issue',
            'category': {'name': 'Market Access'},
            'progressReports': [
              {
                'progressReportId': 2,
                'year': 2026,
                'semester': 'S2',
                'sourceOfVerification': 'System reference name',
              },
            ],
          };
        }
        return http.Response.bytes(
          utf8.encode(jsonEncode({'success': true, 'data': data})),
          200,
        );
      }),
    );
    final settings = AppSettingsController(authRepository: AuthRepository(api))
      ..setLanguage(AppLanguage.english)
      ..setModuleType(AppModuleType.cdcSection);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(
          home: Scaffold(body: CdcSectionIssuesScreenView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Market issue'));
    await tester.tap(find.text('Market issue'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Report S2 2026'));
    expect(find.text('Report S2 2026'), findsOneWidget);
    expect(find.text('System reference name'), findsOneWidget);
    expect(requestedDetails, ['/api/v1/working-group-issues/1']);
  });

  testWidgets('report card and View Details show supplied API data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final issue = sampleApiIssue();
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: CdcSectionIssueDetailScreen(
            title: issue.title,
            category: issue.category,
            issue: issue,
            generalIssue: true,
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Report S1 2025'));
    await tester.pumpAndSettle();
    expect(find.text('Verification details from API'), findsOneWidget);
    expect(find.text('1 Attachments'), findsOneWidget);
    expect(find.textContaining('2:00'), findsOneWidget);
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();
    expect(find.text('Complete'), findsOneWidget);
    expect(find.text('Verification details from API'), findsOneWidget);
    final reference = find.byKey(const ValueKey('progress-reference-name'));
    expect(tester.widget<Text>(reference).maxLines, 2);
    await tester.tap(reference);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(reference).maxLines, isNull);
    expect(find.text('Solution from API'), findsOneWidget);
    expect(find.text('Request Doc'), findsOneWidget);
    expect(find.text('200 KB'), findsOneWidget);
    expect(find.text('https://example.com/verification'), findsNothing);
    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('cdc-progress-report-data-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    for (final text in [
      'Indicators from API',
      'Challenges from API',
      'Requests from API',
      'RGC decision from API',
    ]) {
      final content = find.textContaining(text, findRichText: true);
      await tester.scrollUntilVisible(content, 150, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(content, findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty issue detail reports do not invent a report card', (
    tester,
  ) async {
    final initial = WorkingGroupIssue.fromJson({
      'id': 5,
      'title': 'General issue',
      'progressReports': [],
      'progressSolution': '<p>Progress from matrix list</p>',
      'dateOfIssueSolution': '2026-09-15',
    });
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/working-group-issues/5');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'success': true,
              'data': {
                'id': 5,
                'title': 'General issue',
                'progressReports': [],
              },
            }),
          ),
          200,
        );
      }),
    );
    final settings = AppSettingsController(authRepository: AuthRepository(api))
      ..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: CdcIssueDetailLoader(
            issueId: 5,
            generalIssue: true,
            initialIssue: initial,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Progress Report'), findsNothing);
    expect(find.text('Reference Name'), findsNothing);
    expect(find.text('View Details'), findsNothing);
    expect(find.text('Progress from matrix list'), findsNothing);
    expect(
      find.text('No progress report data is available for this issue.'),
      findsOneWidget,
    );
  });

  for (final detailHasReports in [false, true]) {
    testWidgets(
      'detail ${detailHasReports ? 'overrides' : 'retains'} list reports',
      (tester) async {
        final initial = sampleApiIssue();
        final api = ApiClient(
          client: MockClient((request) async {
            expect(request.url.path, '/api/v1/working-group-issues/1');
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'success': true,
                  'data': {
                    'id': 1,
                    'title': 'Climate Issue',
                    if (detailHasReports)
                      'progressReports': [
                        {'year': 2026, 'semester': 'S2'},
                      ],
                  },
                }),
              ),
              200,
            );
          }),
        );
        final settings = AppSettingsController(
          authRepository: AuthRepository(api),
        )..setLanguage(AppLanguage.english);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: CdcIssueDetailLoader(
                issueId: 1,
                generalIssue: true,
                initialIssue: initial,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(detailHasReports ? 'Report S2 2026' : 'Report S1 2025'),
          findsOneWidget,
        );
        expect(
          find.text(detailHasReports ? 'Report S1 2025' : 'Report S2 2026'),
          findsNothing,
        );
      },
    );
  }
}
