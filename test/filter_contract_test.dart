import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/network/filter_catalog_repository.dart';
import 'package:gpsf_app/core/widgets/filters/api_filter_scope.dart';
import 'package:gpsf_app/core/widgets/filters/filter_models.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/dashboard/data/dashboard_repository.dart';
import 'package:gpsf_app/features/shared/dashboard/data/pswg_dashboard.dart';
import 'package:gpsf_app/features/shared/dashboard/data/working_group_summary.dart';
import 'package:gpsf_app/features/shared/meetings/data/meeting_summaries_repository.dart';
import 'package:gpsf_app/features/shared/meetings/widgets/meeting_requests_list.dart';
import 'package:gpsf_app/features/shared/issues/widgets/wg_issues_list.dart';

http.Response response(Object data, {int? pages}) => http.Response(
  jsonEncode({
    'success': true,
    'data': data,
    if (pages != null) 'meta': {'totalPages': pages},
  }),
  200,
);

void main() {
  test('plenary display labels serialize to documented status codes', () async {
    final api = ApiClient(
      client: MockClient(
        (request) async => response({
          'items': request.url.path.endsWith('/ministries')
              ? [
                  {'id': 3, 'name': 'MAFF'},
                ]
              : [
                  {'id': 1, 'name': '21th', 'status': 'Sent'},
                  {'id': 2, 'name': '20th', 'status': 'Draft'},
                ],
        }, pages: 1),
      ),
    );
    addTearDown(api.close);
    final sections = await FilterCatalogRepository(api).plenaries();
    expect(sections.first.options.map((item) => item.value), ['SENT', 'DRAFT']);
    expect(sections.first.options.map((item) => item.label), ['Sent', 'Draft']);
    expect(
      FilterSelection({
        'statuses': {'SENT', 'DRAFT'},
        'ministryIds': {'3'},
      }).toQuery(),
      {'statuses': 'DRAFT,SENT', 'ministryIds': '3'},
    );
  });
  testWidgets(
    'PSWG semester filtering loads scoped issue details instead of assuming reports are absent',
    (tester) async {
      final calls = <Uri>[];
      final api = ApiClient(
        client: MockClient((request) async {
          calls.add(request.url);
          if (request.url.path.endsWith('/my')) {
            final second = request.url.queryParameters['page'] == '2';
            return response({
              'items': [
                {'id': second ? 2 : 1, 'title': 'Issue ${second ? 2 : 1}'},
              ],
            }, pages: 2);
          }
          final second = request.url.path.endsWith('/2');
          return response({
            'id': second ? 2 : 1,
            'title': 'Issue ${second ? 2 : 1}',
            'progressReports': [
              {
                'progressReportId': 88,
                'progressReport': {
                  'id': 88,
                  'semester': second ? 'S2' : 'S1',
                  'year': 2031,
                },
              },
            ],
          });
        }),
      );
      addTearDown(api.close);
      final settings = AppSettingsController(
        authRepository: AuthRepository(api),
      );
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: WgIssuesList(
                selection: FilterSelection({
                  'local.semester': {'S2'},
                }),
                itemBuilder: (item) => Text(item.title),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Issue 2'), findsOneWidget);
      expect(find.text('Issue 1'), findsNothing);
      expect(
        calls
            .where((uri) => uri.path.endsWith('/my'))
            .map((uri) => uri.queryParameters['page']),
        ['1', '2'],
      );
      expect(
        calls.where((uri) => !uri.path.endsWith('/my')).map((uri) => uri.path),
        ['/api/v1/working-group-issues/1', '/api/v1/working-group-issues/2'],
      );
      expect(
        calls.any((uri) => uri.queryParameters.containsKey('semester')),
        isFalse,
      );
    },
  );
  testWidgets(
    'request filters match separate relation names on later API pages and omit unsupported queries',
    (tester) async {
      final calls = <Uri>[];
      final api = ApiClient(
        client: MockClient((request) async {
          calls.add(request.url);
          final second = request.url.queryParameters['page'] == '2';
          return response([
            {
              'id': second ? 2 : 1,
              'title': second ? 'Matching request' : 'Other request',
              'status': second ? 'SUBMITTED' : 'DRAFT',
              'meetingDate': '2026-09-29T17:00:00.000Z',
              'user': {
                'stakeholders': [
                  {
                    'stakeholder': {
                      'name': second ? 'Law, Tax, and Governance' : 'Tourism',
                    },
                  },
                  {
                    'stakeholder': {'name': 'Banking and Financial Services'},
                  },
                ],
              },
              'governmentAgencies': [
                {
                  'stakeholder': {'name': 'MAFF'},
                },
              ],
            },
          ], pages: 2);
        }),
      );
      addTearDown(api.close);
      final settings = AppSettingsController(
        authRepository: AuthRepository(api),
      );
      addTearDown(settings.dispose);
      final filters = FilterSelection({
        'search': {'budget'},
        'local.workingGroup': {'Law, Tax, and Governance'},
        'local.primaryAgency': {'MAFF'},
        'local.status': {'SUBMITTED'},
        'local.date': {'2026-09-30'},
      });
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: ApiFilterScope(
                queries: {'meeting-requests': filters.toQuery()},
                selections: {'meeting-requests': filters},
                child: MeetingRequestsList(
                  itemBuilder: (item) => Text(item.title),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Matching request'), findsOneWidget);
      expect(find.text('Other request'), findsNothing);
      expect(calls.map((uri) => uri.queryParameters['page']), ['1', '2']);
      for (final uri in calls) {
        expect(
          uri.queryParameters.keys,
          unorderedEquals(['page', 'limit', 'search']),
        );
        expect(uri.queryParameters['search'], 'budget');
      }
    },
  );

  test(
    'summary catalogs and filtering include years and issue counts from later pages',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          final second = request.url.queryParameters['page'] == '2';
          return response({
            'items': [
              {
                'id': second ? 2 : 1,
                'summaryTitle': 'Summary',
                'meetingDate': second ? '2031-01-01' : '2026-01-01',
                'status': second ? 'SENT' : 'DRAFT',
                'issueCount': second ? 17 : 1,
              },
            ],
          }, pages: 2);
        }),
      );
      addTearDown(api.close);
      final sections = await FilterCatalogRepository(api).meetingSummaries();
      expect(sections.map((section) => section.id), [
        'local.status',
        'local.year',
        'local.issueCount',
      ]);
      expect(sections[1].options.map((item) => item.value), ['2026', '2031']);
      final selection = FilterSelection({
        'local.year': {'2031'},
        'local.issueCount': {'17'},
        'local.status': {'SENT'},
      });
      final rows = await MeetingSummariesRepository(api).getSummaries();
      expect(
        rows.where((row) => selection.matchesLocal(row.filterValues)).single.id,
        2,
      );
      expect(selection.toQuery(), isEmpty);
    },
  );

  test(
    'CDC GPSF RGC catalog offers only facets present in its paginated decisions',
    () async {
      final paths = <String>[];
      final api = ApiClient(
        client: MockClient((request) async {
          paths.add(request.url.path);
          expect(request.url.path, '/api/v1/rgc-decisions/cdc-gpsf');
          return response({
            'items': request.url.queryParameters['page'] == '1'
                ? [
                    {
                      'id': 1,
                      'plenaryId': 3,
                      'plenary': {'id': 3, 'name': '21th'},
                      'stakeholderId': 1,
                      'stakeholder': {'id': 1, 'name': 'MAFF'},
                      'categoryId': 5,
                      'categoryInfo': {'id': 5, 'name': 'Climate'},
                      'statusCode': 'NOT_ADDRESSED',
                      'status': 'Not Addressed',
                      'issues': [
                        {
                          'stakeholder': {
                            'name': 'Agriculture and Agro-Industry',
                          },
                        },
                      ],
                      'dateOfDecision': '2026-09-29T17:00:00.000Z',
                    },
                  ]
                : [
                    {
                      'id': 2,
                      'plenaryId': 3,
                      'plenary': {'id': 3, 'name': '21th'},
                      'stakeholderId': 1,
                      'stakeholder': {'id': 1, 'name': 'MAFF'},
                      'categoryId': 5,
                      'categoryInfo': {'id': 5, 'name': 'Climate'},
                      'statusCode': 'SOLVED',
                      'status': 'Solved',
                    },
                  ],
          }, pages: 2);
        }),
      );
      addTearDown(api.close);
      final sections = await FilterCatalogRepository(api).rgc(cdcGpsf: true);
      expect(sections.map((section) => section.id), [
        'plenaryId',
        'status',
        'local.workingGroup',
        'stakeholderId',
        'categoryId',
        'local.dateOfDecision',
      ]);
      expect(sections.map((section) => section.columns), [2, 3, 1, 5, 2, 2]);
      expect(sections[0].options.map((item) => item.value), ['3']);
      expect(sections[1].options.map((item) => item.value), [
        'NOT_ADDRESSED',
        'SOLVED',
      ]);
      expect(sections[2].options.map((item) => item.label), [
        'Agriculture and Agro-Industry',
      ]);
      expect(sections[3].options.map((item) => item.label), ['MAFF']);
      expect(sections[4].options.map((item) => item.label), ['Climate']);
      expect(sections.last.options.map((item) => item.value), [
        '2026-09-30',
        'unspecified',
      ]);
      expect(paths, [
        '/api/v1/rgc-decisions/cdc-gpsf',
        '/api/v1/rgc-decisions/cdc-gpsf',
      ]);
    },
  );

  test(
    'CDC design has original five sections without sending PSWG labels as agency IDs',
    () async {
      final api = ApiClient(
        client: MockClient(
          (request) async => response({
            'categories': [
              {'id': 12, 'name': 'Climate'},
            ],
            'statuses': [
              {'id': 4, 'name': 'Solved'},
            ],
            'workingGroups': [
              {'id': 8, 'name': 'Tourism'},
            ],
            'years': [2031],
          }),
        ),
      );
      addTearDown(api.close);
      final sections = await FilterCatalogRepository(
        api,
      ).issues(matrix: true, cdcDesign: true);
      expect(sections.map((section) => section.id), [
        'categoryIds',
        'issueStatusIds',
        'local.pswgs',
        'years',
        'local.plenaryEscalation',
      ]);
      expect(sections[2].columns, 1);
      expect(sections.last.options.every((option) => option.enabled), isTrue);
      final selection = FilterSelection({
        'local.pswgs': {'Tourism'},
        'categoryIds': {'12'},
      });
      expect(selection.toQuery(), {'categoryIds': '12'});
      expect(
        selection.matchesLocal({
          'local.pswgs': ['Tourism'],
        }),
        isTrue,
      );
      expect(
        selection.matchesLocal({
          'local.pswgs': ['Agriculture'],
        }),
        isFalse,
      );
    },
  );

  test(
    'year loads latest available saved semester and chart filters preserve published totals',
    () async {
      final calls = <Uri>[];
      final api = ApiClient(
        client: MockClient((request) async {
          calls.add(request.url);
          if (request.url.path.endsWith('/saved')) {
            return response([
              {'progressReportId': 11, 'year': 2031, 'semester': 'S1'},
              {'progressReportId': 22, 'year': 2031, 'semester': 'S2'},
            ]);
          }
          return response({
            'cards': {
              'totalIssues': 7,
              'solved': 3,
              'inProgress': 3,
              'notAddressed': 1,
              'totalPrimaryAgencies': 2,
              'totalMinistries': 2,
            },
            'byWorkingGroup': [],
            'byPrimaryAgency': [],
            'byCategory': [],
          });
        }),
      );
      addTearDown(api.close);
      await DashboardRepository(api).getLiveDashboard(year: '2031');
      expect(
        calls.last.path,
        endsWith('/progress-reports/22/dashboards/pswg/final'),
      );
      const row = WorkingGroupSummary(
        id: 1,
        name: 'Tourism',
        total: 7,
        solved: 3,
        inProgress: 3,
        notAddressed: 1,
      );
      final data = PswgDashboard(
        cards: {'totalIssues': 7},
        workingGroups: [row],
        agencies: [],
        categories: [],
      );
      final filtered = data.filtered(
        FilterSelection({
          'local.workingGroup': {'Tourism'},
          'local.status': {'IN_PROGRESS'},
        }),
      );
      expect(filtered.workingGroups.single.total, 3);
      expect(filtered.workingGroups.single.solved, 0);
      expect(filtered.cards['totalIssues'], 7);
      expect(
        data
            .filtered(
              FilterSelection({
                'local.workingGroup': {'Missing'},
              }),
            )
            .workingGroups,
        isEmpty,
      );
    },
  );
}
