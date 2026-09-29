import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/shared/dashboard/data/dashboard_endpoints_repository.dart';
import 'package:gpsf_app/features/shared/dashboard/data/dashboard_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Map<String, dynamic> snapshot() {
    final fixture =
        jsonDecode(File('test/fixtures/plenary.json').readAsStringSync())
            as Map<String, dynamic>;
    final data = fixture['data'] as Map<String, dynamic>;
    (data['cards'] as Map<String, dynamic>).remove('totalMinistries');
    data['report'] = {'id': 7, 'year': 2025, 'semester': 'S1'};
    data['generatedAt'] = '2026-09-29T06:16:35.367Z';
    return data;
  }

  test(
    'both scopes use live, saved and final endpoints with report metadata',
    () async {
      final requests = <String>[];
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          requests.add(request.url.path);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': request.url.path.endsWith('/saved')
                  ? [
                      {
                        'progressReportId': 7,
                        'year': 2025,
                        'semester': 'S1',
                        'status': 'PUBLISHED',
                      },
                    ]
                  : snapshot(),
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final repository = DashboardEndpointsRepository(api);
      for (final scope in DashboardScope.values) {
        final live = await repository.getLiveDashboard(scope: scope);
        expect(live.scope, scope);
        expect(live.cards['totalIssues'], 1);
        expect(live.cards['totalMinistries'], isNull);
        expect(live.workingGroups, isNotEmpty);
        expect(live.report?['semester'], 'S1');
        expect(live.generatedAt, DateTime.parse('2026-09-29T06:16:35.367Z'));
        final saved = await repository.getSavedDashboards(scope: scope);
        expect(saved.single['progressReportId'], 7);
        expect(saved.single['status'], 'PUBLISHED');
        final historical = await repository.getFinalDashboard(
          scope: scope,
          progressReportId: 7,
        );
        expect(historical.report?['year'], 2025);
      }
      expect(requests, [
        for (final scope in DashboardScope.values) ...[
          '/api/v1/dashboards/${scope.name}/live',
          '/api/v1/dashboards/${scope.name}/saved',
          '/api/v1/progress-reports/7/dashboards/${scope.name}/final',
        ],
      ]);
    },
  );

  test(
    'dropdowns retain server fields and distinguish valid empty lists',
    () async {
      final paths = <String>[];
      final api = ApiClient(
        client: MockClient((request) async {
          paths.add(request.url.path);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': request.url.path.endsWith('/statuses')
                  ? [
                      {'id': 2, 'code': 'SOLVED', 'name': 'Solved'},
                    ]
                  : [],
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final repository = DashboardEndpointsRepository(api);
      expect((await repository.getStatuses()).single['code'], 'SOLVED');
      expect(await repository.getCategories(), isEmpty);
      expect(await repository.getGovernmentAgencies(), isEmpty);
      expect(paths, [
        '/api/v1/working-group-issues/statuses',
        '/api/v1/working-group-issues/categories',
        '/api/v1/working-group-issues/government-agencies',
      ]);
    },
  );

  test('explicit items envelope support makes only one request', () async {
    var calls = 0;
    final api = ApiClient(
      client: MockClient((_) async {
        calls++;
        return http.Response(
          '{"success":true,"data":{"items":[{"id":9,"year":2024,"semester":"S2"}]}}',
          200,
        );
      }),
    );
    addTearDown(api.close);
    final repository = DashboardEndpointsRepository(
      api,
      wrappedListEndpoints: {'dashboards/plenary/saved'},
    );
    expect(
      (await repository.getSavedDashboards(
        scope: DashboardScope.plenary,
      )).single['year'],
      2024,
    );
    expect(calls, 1);
  });

  test(
    'invalid IDs, malformed data and HTTP failures are not demo fallbacks',
    () async {
      var calls = 0;
      final api = ApiClient(
        client: MockClient((_) async {
          calls++;
          return http.Response('{"success":true,"data":[null]}', 200);
        }),
      );
      addTearDown(api.close);
      final repository = DashboardEndpointsRepository(api);
      expect(
        () => repository.getFinalDashboard(
          scope: DashboardScope.pswg,
          progressReportId: 0,
        ),
        throwsArgumentError,
      );
      expect(calls, 0);
      await expectLater(repository.getStatuses(), throwsA(isA<ApiException>()));
      final bad = ApiClient(
        client: MockClient(
          (_) async =>
              http.Response('{"success":true,"data":{"cards":{}}}', 200),
        ),
      );
      addTearDown(bad.close);
      await expectLater(
        DashboardEndpointsRepository(
          bad,
        ).getLiveDashboard(scope: DashboardScope.plenary),
        throwsA(isA<ApiException>()),
      );
      final denied = ApiClient(
        client: MockClient(
          (_) async =>
              http.Response('{"success":false,"message":"Access denied"}', 403),
        ),
      );
      addTearDown(denied.close);
      await expectLater(
        DashboardEndpointsRepository(
          denied,
        ).getLiveDashboard(scope: DashboardScope.pswg),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
      );
    },
  );
}
