import 'dart:convert';
import 'package:gpsf_app/features/cdc_section/reports/rgc_decision_details.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decision.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decisions_repository.dart';
import 'package:gpsf_app/screens/report/report_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  test('formats API dates in Cambodia time', () {
    expect(rgcDate(DateTime.parse('2026-09-29T17:00:00.000Z')), 'Sep 30, 2026');
    expect(
      rgcDate(DateTime.parse('2026-09-30T00:00:00+07:00')),
      'Sep 30, 2026',
    );
    expect(rgcDate(DateTime.parse('2026-09-14T00:00:00.000Z')), 'Sep 14, 2026');
    expect(rgcDate(DateTime.parse('2026-09-30')), 'Sep 30, 2026');
    expect(rgcDate(null), '—');
  });
  final response = {
    'success': true,
    'data': {
      'items': [
        {
          'id': 1,
          'stakeholder': {'name': 'MAFF'},
          'category': 'Climate',
          'meetingDate': '2026-09-14T00:00:00.000Z',
          'status': 'Not Addressed',
          'statusCode': 'NOT_ADDRESSED',
          'focalPerson': 'H.E. Mr. DITH TINA',
          'verificationLink': 'https://example.com/verify',
          'issues': [
            {'attachment': '/uploads/issues/reference.pdf'},
          ],
        },
      ],
      'meta': {'total': 1, 'page': 1, 'limit': 10, 'totalPages': 1},
    },
  };

  test('maps the RGC decision response and nested issue link', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/rgc-decisions');
        return http.Response(jsonEncode(response), 200);
      }),
    );
    addTearDown(api.close);

    final decision = (await RgcDecisionsRepository(api).getDecisions()).single;
    expect(decision.agencyName, 'MAFF');
    expect(decision.category, 'Climate');
    expect(decision.statusCode, 'NOT_ADDRESSED');
    expect(decision.linkCount, 2);
  });

  test('loads deadline using the linked plenary ID', () async {
    final requested = <String>[];
    final api = ApiClient(
      client: MockClient((request) async {
        requested.add(request.url.path);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': request.url.path.endsWith('/rgc-decisions/1')
                ? {'id': 1, 'plenaryId': 3}
                : {'id': 3, 'deadline': '2026-09-30T00:00:00.000Z'},
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final detail = await RgcDecisionsRepository(api).getDecision(1);
    expect(detail.deadline, DateTime.utc(2026, 9, 30));
    expect(requested, ['/api/v1/rgc-decisions/1', '/api/v1/plenaries/3']);
  });

  test('keeps decision readable when plenary access fails', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/plenaries/3')) {
          return http.Response(
            jsonEncode({'success': false, 'message': 'Forbidden'}),
            403,
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 1,
              'plenary': {'id': 3},
              'decision': 'Decision text',
            },
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final detail = await RgcDecisionsRepository(api).getDecision(1);
    expect(detail.deadline, isNull);
    expect(detail.issues.single.rgcDecision, 'Decision text');
  });

  test('uses an existing deadline without another request', () async {
    for (final data in [
      {'id': 1, 'plenaryId': 3, 'deadline': '2026-09-30'},
      {
        'id': 1,
        'plenary': {'id': 3, 'deadline': '2026-09-30'},
      },
      {'id': 1},
    ]) {
      var requests = 0;
      final api = ApiClient(
        client: MockClient((request) async {
          requests++;
          return http.Response(
            jsonEncode({'success': true, 'data': data}),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final detail = await RgcDecisionsRepository(api).getDecision(1);
      expect(requests, 1);
      expect(detail.deadline, data.length > 1 ? DateTime(2026, 9, 30) : null);
    }
  });

  test('maps the report filter metadata from API fields', () {
    final decision = RgcDecision({
      'id': 1,
      'plenary': {'name': '21th'},
      'measureCategory': {'name': '8. Banking and Finance Sector'},
      'dateOfDecision': '2026-09-29T17:00:00.000Z',
      'issues': [
        {
          'stakeholder': {'name': 'Banking and Financial Services'},
        },
        {
          'stakeholder': {'name': 'Banking and Financial Services'},
        },
      ],
    });
    expect(decision.plenaryName, '21th');
    expect(decision.workingGroups, ['Banking and Financial Services']);
    expect(decision.measureCategory, '8. Banking and Finance Sector');
    expect(decision.decisionDate, DateTime.utc(2026, 9, 29, 17));
  });

  test('maps issue submitter separately from submitting organization', () {
    final issue = RgcDecisionIssue.fromJson(
      {
        'stakeholder': {'name': 'Agriculture & Agro-Industry'},
        'user': {'name': 'PSWG Secretariat A'},
        'createdAt': '2026-09-03T02:35:59.659Z',
      },
      decision: {'submittedToCdcAt': '2026-09-14T09:00:40.620Z'},
    );
    expect(issue.submittedBy, 'Agriculture & Agro-Industry');
    expect(issue.submittedByName, 'PSWG Secretariat A');
    expect(issue.submittedDate, DateTime.parse('2026-09-03T02:35:59.659Z'));
    final fallback = RgcDecisionIssue.fromJson(
      {
        'stakeholder': {'name': 'MAFF'},
      },
      decision: {'submittedToCdcAt': '2026-09-14T09:00:40.620Z'},
    );
    expect(fallback.submittedByName, 'MAFF');
    expect(fallback.submittedDate, DateTime.parse('2026-09-14T09:00:40.620Z'));
  });

  test('uses issue attachment before meeting documents with fallback', () {
    final meeting = {
      'meetingRequestLetter': {
        'path': '/uploads/request.pdf',
        'name': 'Request',
      },
    };
    final issue = RgcDecisionIssue.fromJson({
      'attachment': '/uploads/issues/1788402959624-Issue_reference.pdf',
      'meetingRequest': meeting,
    });
    expect(
      issue.meetingRequestDocumentPath,
      '/uploads/issues/1788402959624-Issue_reference.pdf',
    );
    expect(
      RgcDecisionIssue.fromJson({
        'attachment': ' ',
        'meetingRequest': meeting,
      }).meetingRequestDocumentPath,
      '/uploads/request.pdf',
    );
    expect(
      RgcDecisionIssue.fromJson({
        'attachment': null,
        'meetingRequest': meeting,
      }).meetingRequestDocumentName,
      'Request',
    );
    expect(RgcDecisionIssue.fromJson({}).meetingRequestDocumentPath, isEmpty);
  });

  test('maps agency order and progress report content', () {
    final issue = RgcDecisionDetail.fromJson({
      'id': 1,
      'indicatorDescription': '',
      'indicatorName': 'Milestone 2',
      'issues': [
        {
          'governmentAgencies': [
            {
              'agencyOrder': 3,
              'stakeholder': {'name': 'MISTI'},
            },
            {
              'agencyOrder': 1,
              'stakeholder': {'name': 'MAFF'},
            },
            {
              'agencyOrder': 2,
              'stakeholder': {'name': 'MEF'},
            },
          ],
        },
      ],
      'progressReports': [
        {
          'indicators': '<p>Report indicator</p>',
          'progressSolution': '<p>Progress <strong>solution</strong></p>',
          'implementationChallenges': '<p>Challenge</p>',
          'requests': '<p>Request</p>',
        },
      ],
    }).issues.single;
    expect(issue.governmentAgencies, {1: 'MAFF', 2: 'MEF', 3: 'MISTI'});
    expect(issue.governmentAgencies[4], isNull);
    expect(issue.indicators, 'Report indicator');
    expect(issue.progressSolution, 'Progress solution');
    expect(issue.implementationChallenges, 'Challenge');
    expect(issue.request, 'Request');
    expect(
      RgcDecisionIssue.fromJson(
        {},
        decision: {'indicatorDescription': '', 'indicatorName': 'Milestone 2'},
      ).indicators,
      'Milestone 2',
    );
  });

  testWidgets('Ministry RGC Decision tab uses the API', (tester) async {
    final settings =
        AppSettingsController(
            authRepository: AuthRepository(
              ApiClient(
                client: MockClient((request) async {
                  if (request.url.path == '/api/v1/progress-reports') {
                    return http.Response(
                      jsonEncode({'success': true, 'data': []}),
                      200,
                    );
                  }
                  return http.Response(jsonEncode(response), 200);
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
        child: const MaterialApp(home: Scaffold(body: ReportScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('RGC Decision'));
    await tester.pumpAndSettle();

    expect(find.text('MAFF'), findsOneWidget);
    expect(find.text('2 Link'), findsOneWidget);
  });
}
