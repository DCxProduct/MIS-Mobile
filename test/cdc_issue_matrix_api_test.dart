import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/shared/issues/data/cdc_issue_matrix_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const counts = {
    'totalIssues': 56,
    'solved': 30,
    'inProgress': 16,
    'notAddressed': 10,
    'totalPrimaryAgencies': 14,
  };

  test(
    'all seven CDC GET endpoints preserve records and query parameters',
    () async {
      final requests = <Uri>[];
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          requests.add(request.url);
          final Object data = switch (request.url.path) {
            '/api/v1/issues/summary' => counts,
            '/api/v1/issues' => {
              'items': [
                {
                  'issueId': 17,
                  'title': 'Inspection',
                  'attachment': [
                    {'id': 4},
                  ],
                },
              ],
              'pagination': {
                'page': 2,
                'limit': 50,
                'total': 56,
                'totalPages': 2,
              },
            },
            '/api/v1/issues/17' => {
              'issueId': 17,
              'rgcDecision': {'text': 'Decision'},
              'attachment': [
                {'id': 4},
              ],
            },
            '/api/v1/translations/dictionary' => {'title': 'បញ្ហា CDC'},
            _ => [
              {'id': 3, 'code': 'SOLVED', 'name': 'Name'},
            ],
          };
          final isPage = request.url.path == '/api/v1/issues';
          return http.Response(
            jsonEncode({
              'success': true,
              'data': isPage ? (data as Map<String, dynamic>)['items'] : data,
              if (isPage) 'meta': (data as Map<String, dynamic>)['pagination'],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);
      final repository = CdcIssueMatrixRepository(api);
      expect((await repository.getSummary()).totalIssues, 56);
      final page = await repository.getIssues(page: 2);
      expect(page.page, 2);
      expect(page.totalPages, 2);
      expect(page.total, 56);
      expect(page.items.single['attachment'], [
        {'id': 4},
      ]);
      expect((await repository.getIssue(17))['rgcDecision'], {
        'text': 'Decision',
      });
      expect((await repository.getWorkingGroups()).single['id'], 3);
      expect((await repository.getGovernmentAgencies()).single['name'], 'Name');
      expect((await repository.getStatuses()).single['code'], 'SOLVED');
      expect((await repository.getDictionary())['title'], 'បញ្ហា CDC');
      expect(requests.map((uri) => uri.path).toList(), [
        '/api/v1/issues/summary',
        '/api/v1/issues',
        '/api/v1/issues/17',
        '/api/v1/stakeholders/working-groups',
        '/api/v1/working-group-issues/government-agencies',
        '/api/v1/working-group-issues/statuses',
        '/api/v1/translations/dictionary',
      ]);
      expect(requests[1].queryParameters, {'page': '2', 'limit': '50'});
      expect(requests.last.queryParameters, {
        'language': 'km',
        'module': 'cdc',
        'page': 'issue-matrix',
      });
    },
  );

  test('default pagination and an empty page retain zero counts', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.url.queryParameters, {'page': '1', 'limit': '50'});
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [],
            'meta': {'page': 1, 'limit': 50, 'total': 0, 'totalPages': 0},
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final page = await CdcIssueMatrixRepository(api).getIssues();
    expect(page.items, isEmpty);
    expect(page.total, 0);
    expect(page.totalPages, 0);
  });

  test(
    'invalid parameters make no request and malformed responses fail',
    () async {
      var calls = 0;
      final api = ApiClient(
        client: MockClient((_) async {
          calls++;
          return http.Response('{"success":true,"data":{"items":[null]}}', 200);
        }),
      );
      addTearDown(api.close);
      final repository = CdcIssueMatrixRepository(api);
      await expectLater(repository.getIssues(page: 0), throwsArgumentError);
      await expectLater(repository.getIssues(limit: 0), throwsArgumentError);
      await expectLater(repository.getIssue(0), throwsArgumentError);
      await expectLater(
        repository.getDictionary(language: ''),
        throwsArgumentError,
      );
      expect(calls, 0);
      await expectLater(repository.getIssues(), throwsA(isA<ApiException>()));
      await expectLater(repository.getSummary(), throwsA(isA<ApiException>()));
    },
  );

  test('explicit wrapped dropdown and HTTP authentication errors', () async {
    var calls = 0;
    final api = ApiClient(
      client: MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('{"success":true,"data":{"items":[]}}', 200)
            : http.Response(
                '{"success":false,"message":"Please sign in"}',
                401,
              );
      }),
    );
    addTearDown(api.close);
    final repository = CdcIssueMatrixRepository(
      api,
      wrappedListEndpoints: {'stakeholders/working-groups'},
    );
    expect(await repository.getWorkingGroups(), isEmpty);
    expect(calls, 1);
    await expectLater(
      repository.getIssue(17),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status', 401),
      ),
    );
    expect(calls, 2);
  });

  test(
    'missing or malformed metadata is not treated as an empty page',
    () async {
      for (final meta in [
        null,
        {'page': 1, 'limit': 50, 'total': -1, 'totalPages': 0},
      ]) {
        final api = ApiClient(
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({'success': true, 'data': [], 'meta': meta}),
              200,
            ),
          ),
        );
        try {
          await expectLater(
            CdcIssueMatrixRepository(api).getIssues(),
            throwsA(isA<ApiException>()),
          );
        } finally {
          api.close();
        }
      }
    },
  );
}
