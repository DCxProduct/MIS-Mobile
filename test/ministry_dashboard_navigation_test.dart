import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/filters/api_filter_sheet.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/line_ministry/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/pswg_live_dashboard.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('ministry dashboard keeps live and saved APIs scoped to each tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <Uri>[];
    final settings =
        AppSettingsController(
            authRepository: AuthRepository(
              ApiClient(
                client: MockClient((request) async {
                  if (request.url.path.endsWith('translations/dictionary')) {
                    expect(request.url.queryParameters['module'], 'pswg');
                    return http.Response('{}', 503);
                  }
                  calls.add(request.url);
                  final path = request.url.path;
                  final plenary = path.contains('/plenary/');
                  final scope = plenary ? 'plenary' : 'pswg';
                  final reportId = plenary ? 31 : 42;
                  if (path == '/api/v1/dashboards/$scope/saved') {
                    expect(request.url.queryParameters, {'finalOnly': 'true'});
                    return http.Response(
                      jsonEncode({
                        'success': true,
                        'data': [
                          {
                            'progressReportId': reportId,
                            'year': 2026,
                            'semester': 'S1',
                          },
                        ],
                      }),
                      200,
                    );
                  }
                  expect(
                    path,
                    anyOf(
                      '/api/v1/dashboards/$scope/live',
                      '/api/v1/progress-reports/$reportId/dashboards/$scope/final',
                    ),
                  );
                  expect(request.url.queryParameters, isEmpty);
                  return http.Response(
                    File(
                      plenary
                          ? 'test/fixtures/plenary.json'
                          : 'test/fixtures/working_groups.json',
                    ).readAsStringSync(),
                    200,
                  );
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
        child: const MaterialApp(
          home: Scaffold(body: LineMinistryDashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls.single.path, '/api/v1/dashboards/plenary/live');

    for (final (label, scope, reportId, total) in [
      ('Plenary', 'plenary', 31, 1),
      ('Working Group', 'pswg', 42, 2),
    ]) {
      await tester.ensureVisible(find.text(label).first);
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(calls.last.path, '/api/v1/dashboards/$scope/live');
      await tester.ensureVisible(find.text('Filter'));
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      expect(calls.skip(calls.length - 2).map((uri) => uri.path), [
        '/api/v1/dashboards/$scope/saved',
        '/api/v1/dashboards/$scope/live',
      ]);
      final sheet = find.byType(ApiFilterSheet);
      expect(
        tester.widget<ApiFilterSheet>(sheet).translationPage,
        scope == 'plenary' ? 'dashboard_plenary' : 'dashboard_working_group',
      );
      Navigator.of(tester.element(sheet)).pop(
        FilterSelection({
          'progressReportId': {'$reportId'},
        }),
      );
      await tester.pumpAndSettle();
      expect(
        calls.last.path,
        '/api/v1/progress-reports/$reportId/dashboards/$scope/final',
      );
      expect(
        tester
            .widget<PswgDataScope>(find.byType(PswgDataScope))
            .data
            .cards['totalIssues'],
        total,
      );
    }

    await tester.ensureVisible(find.text('Plenary').first);
    await tester.tap(find.text('Plenary').first);
    await tester.pumpAndSettle();
    expect(
      calls.last.path,
      '/api/v1/progress-reports/31/dashboards/plenary/final',
    );
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(
      calls.last.path,
      '/api/v1/progress-reports/31/dashboards/plenary/final',
    );
    Navigator.of(
      tester.element(find.byType(ApiFilterSheet)),
    ).pop(FilterSelection());
    await tester.pumpAndSettle();
    expect(calls.last.path, '/api/v1/dashboards/plenary/live');
    expect(tester.takeException(), isNull);
  });
}
