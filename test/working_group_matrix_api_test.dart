import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_section/issues/issues_screen.dart';
import 'package:gpsf_app/features/shared/issues/data/issues_repository.dart';
import 'package:gpsf_app/features/shared/issues/widgets/issue_agency_logo.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const summary = {
    'totalIssues': 1,
    'solved': 1,
    'inProgress': 0,
    'notAddressed': 0,
    'totalPrimaryAgencies': 1,
  };
  Map<String, dynamic> issue(int id) => {
    'id': id,
    'title': 'WG issue $id',
    'issueStatus': {'code': 'SOLVED', 'name': 'Solved'},
    'category': {'name': 'Regulation'},
    'attachment': null,
    'governmentAgencies': [
      {'agencyOrder': 1, 'stakeholder': {'name': 'MAFF', 'logo': '/uploads/maff.jpg'}},
    ],
  };
  http.Response response(Object data, {Object? meta}) => http.Response(
    jsonEncode({'success': true, 'data': data, 'meta': meta}),
    200,
  );

  test('matrix pagination, metadata and auxiliary GET endpoints', () async {
    final requests = <Uri>[];
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        requests.add(request.url);
        final path = request.url.path;
        if (path.endsWith('/issue-matrix/summary')) return response(summary);
        if (path.endsWith('/issue-matrix')) {
          expect(request.url.queryParameters['limit'], '50');
          final page = int.parse(request.url.queryParameters['page']!);
          return response({
            'items': [issue(page)],
            'meta': {'totalPages': 2},
          });
        }
        if (path.endsWith('/filter-options')) {
          return response({
            'years': [2026],
            'statuses': [
              {'id': 1},
            ],
            'workingGroups': [],
          });
        }
        if (path.endsWith('/working-group-issues/14')) {
          return response(issue(14));
        }
        if (path.endsWith('/dictionary')) {
          expect(request.url.queryParameters, {
            'module': 'cdc',
            'page': 'issue_matrix',
            'language': 'km',
          });
          return response({'title': 'Issues'});
        }
        return response([
          {'id': 1, 'name': 'Option', 'logo': '/logo.png'},
        ]);
      }),
    );
    addTearDown(api.close);
    final repo = IssuesRepository(api);
    expect((await repo.getIssueMatrixSummary()).solved, 1);
    expect((await repo.getIssueMatrix()).map((item) => item.id), [1, 2]);
    expect((await repo.getMatrixFilterOptions())['years'], [2026]);
    expect((await repo.getIssue(14)).title, 'WG issue 14');
    expect((await repo.getStatuses()).single['id'], 1);
    expect((await repo.getCategories()).single['name'], 'Option');
    expect((await repo.getGovernmentAgencies()).single['logo'], '/logo.png');
    expect((await repo.getMatrixDictionary())['title'], 'Issues');
    expect(requests.map((uri) => uri.path), [
      '/api/v1/working-group-issues/issue-matrix/summary',
      '/api/v1/working-group-issues/issue-matrix',
      '/api/v1/working-group-issues/issue-matrix',
      '/api/v1/working-group-issues/issue-matrix/filter-options',
      '/api/v1/working-group-issues/14',
      '/api/v1/working-group-issues/statuses',
      '/api/v1/working-group-issues/categories',
      '/api/v1/working-group-issues/government-agencies',
      '/api/v1/translations/dictionary',
    ]);
  });

  test(
    'export preserves binary bytes, filters, and authentication failures',
    () async {
      var calls = 0;
      final bytes = [80, 75, 3, 4, 255, 0, 42];
      final filters = {
        'lang': 'km',
        'search': 'tax & trade',
        'years': '2026',
        'ownerStakeholderIds': '14',
        'issueStatusIds': '1',
        'categoryIds': '2',
        'primaryAgencyIds': '3',
        'hasAttachment': 'true',
      };
      final api = ApiClient(
        client: MockClient((request) async {
          calls++;
          expect(
            request.url.path,
            '/api/v1/working-group-issues/issue-matrix/export',
          );
          expect(request.url.queryParameters, filters);
          return calls == 1
              ? http.Response.bytes(bytes, 200)
              : http.Response('{"success":false,"message":"Sign in"}', 401);
        }),
      );
      addTearDown(api.close);
      final repo = IssuesRepository(api);
      expect(await repo.exportMatrix(query: filters), bytes);
      await expectLater(
        repo.exportMatrix(query: filters),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'status',
            401,
          ),
        ),
      );
    },
  );

  testWidgets('CDC Issues uses WG summary/list/detail without CDC matrix API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final paths = <String>[];
    final settings =
        AppSettingsController(
            authRepository: AuthRepository(
              ApiClient(
                client: MockClient((request) async {
                  final path = request.url.path;
                  paths.add(path);
                  if (path.endsWith('/summary')) return response(summary);
                  if (path.endsWith('/14')) {
                    return response({
                      ...issue(14),
                      'description': 'Full WG detail',
                      'governmentAgencies': [
                        {
                          'agencyOrder': 1,
                          'stakeholder': {'name': 'WG Ministry'},
                        },
                      ],
                    });
                  }
                  expect(path, '/api/v1/working-group-issues/issue-matrix');
                  return response({
                    'items': [issue(14)],
                    'meta': {'totalPages': 1},
                  });
                }),
              ),
            ),
          )
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
    expect(find.text('WG issue 14'), findsOneWidget);
    expect(tester.widget<IssueAgencyLogo>(find.byType(IssueAgencyLogo)).path,
        '/uploads/maff.jpg');
    expect(find.text('1/1'), findsOneWidget);
    await tester.ensureVisible(find.text('WG issue 14'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WG issue 14'));
    await tester.pumpAndSettle();
    expect(find.text('WG Ministry'), findsOneWidget);
    expect(find.text('Full WG detail'), findsOneWidget);
    expect(paths, [
      '/api/v1/working-group-issues/issue-matrix/summary',
      '/api/v1/working-group-issues/issue-matrix',
      '/api/v1/working-group-issues/14',
    ]);
    expect(tester.takeException(), isNull);
  });
}
