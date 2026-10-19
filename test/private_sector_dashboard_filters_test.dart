import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/network/filter_catalog_repository.dart';
import 'package:gpsf_app/core/widgets/filters/filter_models.dart';
import 'package:gpsf_app/features/shared/dashboard/data/dashboard_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final scope in DashboardScope.values) {
    test('${scope.name} uses finalized periods and filters locally', () async {
      final requests = <Uri>[];
      final payload =
          jsonDecode(
                File(
                  'test/fixtures/plenary_live_report.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final api = ApiClient(
        client: MockClient((request) async {
          requests.add(request.url);
          if (request.url.path.endsWith('/saved')) {
            expect(request.url.queryParameters, {'finalOnly': 'true'});
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {'progressReportId': 31, 'year': 2026, 'semester': 'S1'},
                  {'progressReportId': 42, 'year': 2026, 'semester': 'S2'},
                  {'progressReportId': 15, 'year': 2025, 'semester': 'S2'},
                ],
              }),
              200,
            );
          }
          expect(request.url.queryParameters, isEmpty);
          expect(
            request.url.path,
            anyOf(
              '/api/v1/dashboards/${scope.name}/live',
              '/api/v1/progress-reports/31/dashboards/${scope.name}/final',
              '/api/v1/progress-reports/42/dashboards/${scope.name}/final',
            ),
          );
          return http.Response(
            jsonEncode(payload),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);
      final catalog = FilterCatalogRepository(api);
      final sections = await catalog.dashboard(scope.name);
      expect(
        sections
            .singleWhere((s) => s.id == 'local.year')
            .options
            .map((o) => o.value),
        ['2026', '2025'],
      );
      expect(sections.last.options.map((o) => o.label), [
        'S1 2026',
        'S2 2026',
        'S2 2025',
      ]);
      expect(requests.map((u) => u.path), [
        '/api/v1/dashboards/${scope.name}/saved',
        '/api/v1/dashboards/${scope.name}/live',
      ]);
      await catalog.dashboard(scope.name, progressReportId: 31);
      expect(
        requests.last.path,
        '/api/v1/progress-reports/31/dashboards/${scope.name}/final',
      );
      await catalog.dashboard(scope.name, year: '2026');
      expect(
        requests.last.path,
        '/api/v1/progress-reports/42/dashboards/${scope.name}/final',
      );
      final repository = DashboardRepository(api);
      await repository.getLiveDashboard(scope: scope, year: '2026');
      expect(
        requests.last.path,
        '/api/v1/progress-reports/42/dashboards/${scope.name}/final',
      );
      await expectLater(
        repository.getLiveDashboard(scope: scope, year: '2024'),
        throwsA(isA<ApiException>()),
      );
      final live = await repository.getLiveDashboard(scope: scope);
      final before = requests.length;
      final filtered = live.filtered(
        FilterSelection({
          'local.status': {'SOLVED'},
          'local.workingGroup': {live.workingGroups.first.name},
          'local.primaryAgency': {live.agencies.first.name},
          'local.category': {live.categories.first.name},
        }),
      );
      expect(requests.length, before);
      expect(filtered.workingGroups, hasLength(1));
      expect(filtered.agencies, hasLength(1));
      expect(filtered.categories, hasLength(1));
      expect(filtered.cards['notAddressed'], 0);
      expect(filtered.cards['inProgress'], 0);
      expect(filtered.cards['totalIssues'], live.cards['solved']);
      expect(filtered.workingGroups.first.notAddressed, 0);
      expect(live.cards['notAddressed'], 1);
      expect(live.filtered(FilterSelection()).cards, live.cards);
    });
  }
}
