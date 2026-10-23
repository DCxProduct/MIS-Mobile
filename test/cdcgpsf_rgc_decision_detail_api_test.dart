import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_secretariat/issues/issues_screen.dart';
import 'package:gpsf_app/features/cdc_section/reports/rgc_decision_details.dart';
import 'package:gpsf_app/features/cdc_secretariat/reports/rgc_decision_card.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decisions_repository.dart';
import 'package:gpsf_app/screens/report/rgc_decision_detail_screen.dart';
import 'package:gpsf_app/screens/report/plenary_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

http.Response ok(Object data) =>
    http.Response(jsonEncode({'success': true, 'data': data}), 200);

Map<String, dynamic> decision(int id) => {
  'id': id,
  'stakeholder': {'id': 1, 'name': 'MAFF'},
  'meetingDate': '2026-10-03T00:00:00Z',
  'category': 'Communication',
  'status': 'Not Addressed',
  'statusCode': 'NOT_ADDRESSED',
  'focalPerson': 'API focal person',
  'decision': 'Selected decision $id',
  'indicatorName': 'Milestone 1',
  'verificationSource': '<ul><li>Original verification source</li></ul>',
  'verificationLink': 'https://example.com/verify',
  'submittedToCdcAt': '2026-10-03T03:00:00Z',
  'issues': [
    for (final index in [1, 2])
      {
        'id': id * 10 + index,
        'title': 'API issue $id/$index',
        'description': 'Actual description $id/$index',
        'recommendation': 'Actual recommendation $id/$index',
        'stakeholder': {'name': 'API working group $index'},
        'user': {'name': 'API submitter $index'},
        'createdAt': '2026-10-02T00:00:00Z',
        'category': {'name': 'Communication'},
        'governmentAgencies': [
          {
            'agencyOrder': 1,
            'stakeholder': {'id': 1, 'name': 'MAFF'},
          },
        ],
        'meetingRequest': {
          'id': 11,
          'meetingRequestLetter': {
            'path': '/uploads/request.pdf',
            'name': 'Request.pdf',
          },
        },
      },
  ],
  'progressReports': [
    for (final semester in ['S1', 'S2'])
      {
        'progressReportId': id * 100,
        'year': 2028,
        'semester': semester,
        'dateOfIssueSolution': '2028-05-16',
        'status': 'In Progress',
        'referenceName': 'Reference $id/$semester',
        'indicators': 'Report indicator $id/$semester',
        'progressSolution': 'Report progress $id/$semester',
        'implementationChallenges': 'Report challenges $id/$semester',
        'requests': 'Report requests $id/$semester',
        'attachment': {
          'path': '/uploads/$id-$semester.pdf',
          'name': '$semester.pdf',
          'size': 1947246,
        },
      },
  ],
  'plenary': {'id': 1, 'status': 'COMPLETED', 'meetingDate': '2026-10-03'},
};

void main() {
  Future<void> mount(
    WidgetTester tester,
    Widget home,
    Future<http.Response> Function(http.Request) handler,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(client: MockClient(handler));
    addTearDown(api.close);
    final settings = AppSettingsController(authRepository: AuthRepository(api))
      ..setLanguage(AppLanguage.english)
      ..setModuleType(AppModuleType.cdcSecretariat);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'CDC GPSF list opens selected decision ID and all actual issue details',
    (tester) async {
      final calls = <String>[];
      await mount(
        tester,
        const Scaffold(body: CdcSecretariatIssuesScreenView()),
        (request) async {
          calls.add(request.url.path);
          switch (request.url.path) {
            case '/api/v1/rgc-decisions/scorecard':
              return ok({
                'total': 2,
                'byStatus': [
                  {'status': 'Not Addressed', 'count': 2},
                ],
              });
            case '/api/v1/rgc-decisions/cdc-gpsf':
              return ok({
                'items': [decision(3), decision(4)],
                'meta': {'totalPages': 1},
              });
            case '/api/v1/rgc-decisions/3':
              return ok(decision(3));
            case '/api/v1/rgc-decisions/4':
              return ok(decision(4));
            default:
              throw StateError('Unexpected request ${request.url}');
          }
        },
      );
      expect(find.byType(CdcGpsfRgcDecisionCard), findsNWidgets(2));
      final secondButton = find
          .widgetWithText(FilledButton, 'View Details')
          .last;
      await tester.ensureVisible(secondButton);
      await tester.pumpAndSettle();
      await tester.tap(secondButton);
      await tester.pumpAndSettle();
      expect(calls, contains('/api/v1/rgc-decisions/cdc-gpsf'));
      expect(
        calls.where((path) => path == '/api/v1/rgc-decisions/4'),
        hasLength(1),
      );
      expect(calls, isNot(contains('/api/v1/rgc-decisions/3')));
      expect(find.byType(CdcRgcDecisionOverviewScreen), findsNothing);
      final body = tester.widget<CdcGpsfRgcDecisionDetail>(
        find.byType(CdcGpsfRgcDecisionDetail),
      );
      expect(body.detail.decision.id, 4);
      expect(body.detail.issues.map((issue) => issue.description), [
        'Actual description 4/1',
        'Actual description 4/2',
      ]);
      expect(body.detail.decisionContent, 'Selected decision 4');
      expect(body.detail.indicatorName, 'Milestone 1');
      expect(body.detail.workflowStatus, 'Submitted');
      expect(body.detail.progressReports, hasLength(2));
      expect(find.textContaining('Sabada'), findsNothing);
      expect(find.text('Legislation'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Actual description 4/2'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Actual description 4/2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('detail API failure offers retry instead of sample data', (
    tester,
  ) async {
    var calls = 0;
    await mount(tester, const RgcDecisionDetailScreen(decisionId: 4), (
      request,
    ) async {
      expect(request.url.path, '/api/v1/rgc-decisions/4');
      calls++;
      return calls == 1
          ? http.Response('{"message":"Unavailable"}', 500)
          : ok(decision(4));
    });
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CdcGpsfRgcDecisionDetail), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const ValueKey('cdc-gpsf-rgc-detail')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('plenary decision opens API detail with progress reports', (
    tester,
  ) async {
    final calls = <String>[];
    await mount(
      tester,
      const PlenaryDetailScreen(title: 'Plenary 22', plenaryId: 1),
      (request) async {
        calls.add(request.url.path);
        switch (request.url.path) {
          case '/api/v1/plenaries/1':
            return ok({
              'id': 1,
              'name': 'Plenary 22',
              'numberOfRgcDecisions': 1,
            });
          case '/api/v1/rgc-decisions':
            expect(request.url.queryParameters['plenaryId'], '1');
            return ok({
              'items': [decision(4)],
              'meta': {'totalPages': 1},
            });
          case '/api/v1/rgc-decisions/4':
            return ok(decision(4));
          default:
            throw StateError('Unexpected request ${request.url}');
        }
      },
    );
    await tester.tap(find.text('Selected decision 4'));
    await tester.pumpAndSettle();
    expect(calls, contains('/api/v1/rgc-decisions/4'));
    expect(find.byType(CdcGpsfRgcDecisionDetail), findsOneWidget);
    final firstTab = find.widgetWithText(ChoiceChip, 'Report S1 2028');
    await tester.scrollUntilVisible(
      firstTab,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(firstTab, findsOneWidget);
    expect(find.text('Reference 4/S1'), findsOneWidget);
    expect(find.text('S1.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all report semesters retain their own data and PDF', (
    tester,
  ) async {
    await mount(
      tester,
      const RgcDecisionDetailScreen(decisionId: 4),
      (_) async => ok(decision(4)),
    );
    final scrollable = find.byType(Scrollable).first;
    final firstTab = find.widgetWithText(ChoiceChip, 'Report S1 2028');
    await tester.scrollUntilVisible(firstTab, 300, scrollable: scrollable);
    expect(find.widgetWithText(ChoiceChip, 'Report S2 2028'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Report progress 4/S1'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('Report progress 4/S1'), findsOneWidget);
    expect(find.text('Reference Name'), findsOneWidget);
    expect(find.text('Reference 4/S1'), findsOneWidget);
    expect(find.text('S1.pdf'), findsOneWidget);
    await tester.ensureVisible(firstTab);
    await tester.pumpAndSettle();
    final secondTab = find.widgetWithText(ChoiceChip, 'Report S2 2028');
    await tester.ensureVisible(secondTab);
    await tester.pumpAndSettle();
    await tester.tap(secondTab);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Report progress 4/S2'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('Report progress 4/S2'), findsOneWidget);
    expect(find.text('Reference 4/S2'), findsOneWidget);
    expect(find.text('Reference 4/S1'), findsNothing);
    expect(find.text('Report progress 4/S1'), findsNothing);
    expect(find.text('S2.pdf'), findsOneWidget);
    expect(find.text('S1.pdf'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('CDC GPSF list keeps all filters across pages with limit 10', () async {
    final calls = <http.Request>[];
    final filters = {
      'search': 'tourism',
      'plenaryId': '6',
      'stakeholderId': '2',
      'categoryId': '4',
      'status': 'NOT_ADDRESSED',
    };
    final api = ApiClient(
      client: MockClient((request) async {
        calls.add(request);
        expect(request.url.path, '/api/v1/rgc-decisions/cdc-gpsf');
        final page = int.parse(request.url.queryParameters['page']!);
        return ok({
          'items': [decision(page)],
          'meta': {'totalPages': 2},
        });
      }),
    );
    addTearDown(api.close);
    final rows = await RgcDecisionsRepository(
      api,
    ).getDecisions(cdcGpsf: true, filters: filters);
    expect(rows.map((row) => row.id), [1, 2]);
    expect(calls, hasLength(2));
    for (var index = 0; index < calls.length; index++) {
      expect(calls[index].url.queryParameters, {
        ...filters,
        'page': '${index + 1}',
        'limit': '10',
      });
    }
  });
}
