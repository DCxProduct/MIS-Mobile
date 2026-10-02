import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/config/module_repositories.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/network/filter_catalog_repository.dart';
import 'package:gpsf_app/core/widgets/filters/api_filter_sheet.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/private_sector/issues/issues_screen.dart';
import 'package:gpsf_app/features/shared/dashboard/data/dashboard_repository.dart';
import 'package:gpsf_app/features/shared/issues/data/cdc_issue_matrix_repository.dart';
import 'package:gpsf_app/features/shared/issues/data/issues_repository.dart';
import 'package:gpsf_app/translations/app_language.dart';

http.Response ok(Object data, {Object? meta}) => http.Response(
  jsonEncode({'success': true, 'data': data, 'meta': ?meta}),
  200,
);
const catalog = {
  'statuses': [
    {'id': 71, 'name': 'API status'},
  ],
  'categories': [
    {'id': 82, 'name': 'API category'},
  ],
  'governmentAgencies': [
    {'id': 93, 'name': 'API agency'},
  ],
  'years': [2031],
};

void main() {
  testWidgets('CDC issue-matrix Plenary options respond to taps', (
    tester,
  ) async {
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final api = ApiClient(
      client: MockClient(
        (request) async => ok({
          'categories': [
            {'id': 1, 'name': 'General'},
          ],
          'statuses': [
            {'id': 1, 'name': 'In Progress'},
          ],
          'workingGroups': [
            {'id': 1, 'name': 'Agriculture and Agro-Industry'},
          ],
          'years': [2026],
        }),
      ),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: ApiFilterSheet(
            initial: FilterSelection(),
            load: () => FilterCatalogRepository(
              api,
            ).issues(matrix: true, cdcDesign: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final yes = find.byKey(
      const ValueKey('filter-local.plenaryEscalation-true'),
    );
    await tester.ensureVisible(yes);
    await tester.tap(yes);
    await tester.pump();
    expect(
      find.descendant(of: yes, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    final no = find.byKey(
      const ValueKey('filter-local.plenaryEscalation-false'),
    );
    await tester.tap(no);
    await tester.pump();
    expect(
      find.descendant(of: no, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: yes, matching: find.byIcon(Icons.check)),
      findsNothing,
    );
  });

  test(
    'CDC issue-matrix Plenary Yes/No filters API escalation values',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/filter-options')) {
            return ok({
              'categories': [
                {'id': 1, 'name': 'General'},
              ],
              'statuses': [
                {'id': 1, 'name': 'In Progress'},
              ],
              'workingGroups': [
                {'id': 1, 'name': 'Agriculture and Agro-Industry'},
              ],
              'years': [2026],
            });
          }
          expect(request.url.path, '/api/v1/working-group-issues/issue-matrix');
          return ok({
            'items': [
              {'id': 1, 'title': 'For plenary', 'escalation': true},
              {'id': 2, 'title': 'Not for plenary', 'escalation': false},
            ],
            'meta': {'totalPages': 1},
          });
        }),
      );
      addTearDown(api.close);
      final sections = await FilterCatalogRepository(
        api,
      ).issues(matrix: true, cdcDesign: true);
      expect(sections.last.options.every((option) => option.enabled), isTrue);
      final issues = await IssuesRepository(api).getIssueMatrix();
      final yes = FilterSelection({
        'local.plenaryEscalation': {'true'},
      });
      final no = FilterSelection({
        'local.plenaryEscalation': {'false'},
      });
      expect(
        issues.where((issue) => yes.matchesLocal(issue.filterValues)).single.id,
        1,
      );
      expect(
        issues.where((issue) => no.matchesLocal(issue.filterValues)).single.id,
        2,
      );
    },
  );

  test('CDC Plenary Escalation uses the /issues escalation field', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/issues');
        return ok(
          [
            {
              'issueId': 1,
              'title': 'Escalated issue',
              'category': 'General',
              'workingGroup': {'name': 'Agriculture and Agro-Industry'},
              'attachment': null,
              'escalation': true,
            },
            {
              'issueId': 2,
              'title': 'Not escalated issue',
              'category': 'General',
              'workingGroup': {'name': 'Tourism'},
              'attachment': null,
              'escalation': null,
            },
          ],
          meta: {'page': 1, 'limit': 50, 'total': 2, 'totalPages': 1},
        );
      }),
    );
    addTearDown(api.close);
    final sections = await FilterCatalogRepository(api).cdcIssues();
    expect(sections[2].id, 'local.pswgs');
    expect(sections[2].columns, 1);
    expect(sections.last.options.every((option) => option.enabled), isTrue);
    final issues = await CdcIssueMatrixRepository(api).getDisplayIssues();
    expect(issues.map((issue) => issue.plenaryEscalation), [true, false]);
    final yes = FilterSelection({
      'local.plenaryEscalation': {'true'},
    });
    final no = FilterSelection({
      'local.plenaryEscalation': {'false'},
    });
    expect(
      issues.where((issue) => yes.matchesLocal(issue.filterValues)).single.id,
      1,
    );
    expect(
      issues.where((issue) => no.matchesLocal(issue.filterValues)).single.id,
      2,
    );
  });

  test(
    'every module uses its own API client for catalogs and ID queries',
    () async {
      final clients = <ApiClient>[];
      final requests = <String>[];
      final repos = <AppModuleType, ModuleRepositories>{};
      for (final module in AppModuleType.values) {
        final api = ApiClient(
          client: MockClient((request) async {
            requests.add('${module.name}:${request.url.path}');
            return ok(catalog);
          }),
        );
        clients.add(api);
        repos[module] = ModuleRepositories(apiClient: api);
      }
      addTearDown(() {
        for (final api in clients) {
          api.close();
        }
      });
      final settings = AppSettingsController(moduleRepositories: repos);
      addTearDown(settings.dispose);
      for (final module in AppModuleType.values) {
        settings.setModuleType(module);
        final sections = await settings.filters.issues(matrix: true);
        expect(sections.first.options.single.value, '82');
        expect(sections.first.options.single.label, 'API category');
        expect(sections.last.options.single.value, '2031');
        expect(requests.last, contains('${module.name}:'));
      }
      expect(
        FilterSelection({
          'issueStatusIds': {'71', '72'},
          'years': {},
        }).toQuery(),
        {'issueStatusIds': '71,72'},
      );
    },
  );

  testWidgets(
    'issue Apply sends IDs, reloads all pages, Cancel preserves applied values, Clear removes query',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <Uri>[];
      final api = ApiClient(
        client: MockClient((request) async {
          requests.add(request.url);
          final path = request.url.path;
          if (path.endsWith('/progress-reports')) {
            return ok([
              {'semester': 'S2'},
            ]);
          }
          if (path.endsWith('/filter-options')) return ok(catalog);
          if (path.endsWith('/summary/my')) {
            return ok({
              'totalIssues': 2,
              'solved': 1,
              'inProgress': 1,
              'notAddressed': 0,
              'totalPrimaryAgencies': 1,
            });
          }
          if (path.endsWith('/working-group-issues/my')) {
            final filtered = request.url.queryParameters['years'] == '2031';
            final page = request.url.queryParameters['page'];
            return ok({
              'items': [
                {
                  'id': page == '2' ? 2 : 1,
                  'title': filtered
                      ? 'Server filtered issue'
                      : 'Server page $page',
                  'issueStatus': {'code': 'SOLVED', 'name': 'Solved'},
                },
              ],
              'meta': {'totalPages': filtered ? 1 : 2},
            });
          }
          return http.Response('{}', 404);
        }),
      );
      final settings =
          AppSettingsController(authRepository: AuthRepository(api))
            ..setLanguage(AppLanguage.english)
            ..setModuleType(AppModuleType.privateSector);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: Scaffold(body: IssuesScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Server page 1'), findsOneWidget);
      expect(find.text('Server page 2'), findsOneWidget);
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      expect(find.text('API status'), findsOneWidget);
      expect(find.text('2031'), findsOneWidget);
      expect(find.text('2025'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('filter-years-2031')));
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters['years'], '2031');
      expect(requests.last.queryParameters['page'], '1');
      expect(find.text('Server filtered issue'), findsOneWidget);
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter-years-2031')));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Filter'), findsOneWidget);
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter-years-2031')));
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters.containsKey('years'), isFalse);
      expect(find.text('Server page 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed catalogs retry and never supply static fallback options',
    (tester) async {
      var calls = 0;
      final settings = AppSettingsController()
        ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: ApiFilterSheet(
                initial: FilterSelection(),
                load: () async {
                  calls++;
                  if (calls == 1) throw const ApiException('Offline');
                  return const [
                    FilterSection(
                      id: 'status',
                      title: 'Status',
                      options: [FilterOption(value: 'LIVE', label: 'API only')],
                    ),
                  ];
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('filter-status-LIVE')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('API only'), findsOneWidget);
    },
  );

  test(
    'dashboard category choices filter API rows and periods load saved snapshots',
    () async {
      final requests = <Uri>[];
      final api = ApiClient(
        client: MockClient((request) async {
          requests.add(request.url);
          if (request.url.path.endsWith('/saved')) {
            return ok([
              {'progressReportId': 404, 'year': 2031, 'semester': 'S2'},
            ]);
          }
          return ok({
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
            'byCategory': [
              {
                'categoryId': 12,
                'categoryName': 'API category A',
                'total': 4,
                'solved': 2,
                'inProgress': 1,
                'notAddressed': 1,
              },
              {
                'categoryId': 15,
                'categoryName': 'API category B',
                'total': 3,
                'solved': 1,
                'inProgress': 2,
                'notAddressed': 0,
              },
            ],
          });
        }),
      );
      addTearDown(api.close);
      final sections = await FilterCatalogRepository(api).dashboard('pswg');
      expect(sections.map((section) => section.id), [
        'local.workingGroup',
        'local.status',
        'local.primaryAgency',
        'local.category',
        'local.year',
        'progressReportId',
      ]);
      final workingGroupCategory = sections.firstWhere(
        (section) => section.id == 'local.category',
      );
      expect(workingGroupCategory.title, 'filterCategory');
      expect(workingGroupCategory.columns, 2);
      expect(workingGroupCategory.options.map((option) => option.label), [
        'API category A',
        'API category B',
      ]);
      expect(sections.last.options.single.value, '404');
      expect(sections.last.options.single.label, 'S2 2031');
      expect(sections.last.options.single.year, '2031');
      final plenarySections = await FilterCatalogRepository(
        api,
      ).dashboard('plenary');
      final categoryIndex = plenarySections.indexWhere(
        (section) => section.id == 'local.category',
      );
      expect(plenarySections[categoryIndex - 1].id, 'local.primaryAgency');
      final category = plenarySections[categoryIndex];
      expect(category.title, 'measureCategory');
      expect(category.columns, 2);
      expect(category.collapsedItemCount, 5);
      expect(category.options.map((option) => option.label), [
        'API category A',
        'API category B',
      ]);
      final data = await DashboardRepository(
        api,
      ).getLiveDashboard(progressReportId: 404);
      expect(data.cards['totalIssues'], 7);
      final selected = FilterSelection({
        'local.category': {category.options.last.value},
      });
      expect(data.filtered(selected).categories.single.name, 'API category B');
      expect(data.filtered(selected).categories.single.total, 3);
      expect(data.filtered(FilterSelection()).categories, hasLength(2));
      expect(selected.toQuery(), isEmpty);
      expect(
        requests.last.path,
        endsWith('/progress-reports/404/dashboards/pswg/final'),
      );
    },
  );
}
