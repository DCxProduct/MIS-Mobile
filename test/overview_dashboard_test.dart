import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/network/filter_catalog_repository.dart';
import 'package:gpsf_app/core/widgets/filters/api_filter_sheet.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/private_sector/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/features/private_sector/dashboard/tabs/overall_tab.dart';
import 'package:gpsf_app/features/shared/dashboard/data/dashboard_repository.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/agency_status_bars.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/category_totals_chart.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/pswg_live_dashboard.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/working_group_list.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final overview = File('test/fixtures/overview_live.json').readAsStringSync();

  test(
    'overview accepts the supplied live contract and only uses live filters',
    () async {
      final calls = <Uri>[];
      final api = ApiClient(
        client: MockClient((request) async {
          calls.add(request.url);
          expect(request.url.path, '/api/v1/dashboards/overview/live');
          expect(request.url.queryParameters, isEmpty);
          return http.Response(
            overview,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);
      final data = await DashboardRepository(
        api,
      ).getLiveDashboard(scope: DashboardScope.overview);
      expect(data.cards['totalIssues'], 424);
      expect(data.cards['solved'], 391);
      expect(data.cards['inProgress'], 33);
      expect(data.cards['notAddressed'], 0);
      expect(data.cards['totalPrimaryAgencies'], 18);
      expect(data.cards['totalMinistries'], isNull);
      expect(data.workingGroups.length, 17);
      expect(data.agencies.length, 18);
      expect(data.categories.length, 17);
      expect(data.categories.first.khmerName, 'អភិបាលកិច្ច');
      final sections = await FilterCatalogRepository(api).dashboard('overview');
      expect(sections.map((section) => section.id), [
        'local.workingGroup',
        'local.status',
        'local.primaryAgency',
        'local.category',
      ]);
      expect(sections.first.options.length, 17);
      expect(sections[2].options.length, 18);
      expect(calls.length, 2);
    },
  );

  for (final role in AppModuleType.values) {
    testWidgets(
      '$role opens Overview with shared charts and isolated filters',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final calls = <Uri>[];
        final api = ApiClient(
          client: MockClient((request) async {
            if (request.url.path.endsWith('translations/dictionary')) {
              return http.Response('{}', 503);
            }
            calls.add(request.url);
            final file = switch (request.url.path) {
              '/api/v1/dashboards/overview/live' => 'overview_live.json',
              '/api/v1/dashboards/pswg/live' => 'working_groups.json',
              '/api/v1/dashboards/plenary/live' => 'plenary.json',
              _ => throw StateError('Unexpected request: ${request.url}'),
            };
            return http.Response(
              File('test/fixtures/$file').readAsStringSync(),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
        addTearDown(api.close);
        final settings =
            AppSettingsController(authRepository: AuthRepository(api))
              ..setLanguage(AppLanguage.english)
              ..setModuleType(role);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: const MaterialApp(home: DashboardScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        Future<void> selectScope(int index) async {
          final pill = find.byKey(
            ValueKey(
              role == AppModuleType.cdcSecretariat
                  ? 'bottom-nav-${index == 2 ? 5 : 0}'
                  : 'dashboard-scope-$index',
            ),
          );
          await tester.ensureVisible(pill);
          await tester.tap(pill);
          await tester.pumpAndSettle();
        }

        expect(calls.map((uri) => uri.path), [
          '/api/v1/dashboards/overview/live',
        ]);
        if (role == AppModuleType.cdcSecretariat) {
          expect(find.byKey(const ValueKey('dashboard-scope-2')), findsNothing);
          expect(find.byKey(const ValueKey('dashboard-scope-1')), findsNothing);
          expect(find.byKey(const ValueKey('bottom-nav-5')), findsOneWidget);
          expect(
            tester.getTopLeft(find.byKey(const ValueKey('bottom-nav-5'))).dx,
            lessThan(
              tester.getTopLeft(find.byKey(const ValueKey('bottom-nav-0'))).dx,
            ),
          );
        }
        expect(calls.last.path, '/api/v1/dashboards/overview/live');
        expect(find.text('G-PSF Overview'), findsNWidgets(2));
        expect(find.text('391/424'), findsOneWidget);
        expect(find.text('33/424'), findsOneWidget);
        expect(find.text('0/424'), findsOneWidget);
        expect(find.text('18'), findsOneWidget);
        expect(
          tester
              .widget<SharedDashboardCharts>(find.byType(SharedDashboardCharts))
              .plenary,
          isFalse,
        );
        final beforeCharts = calls.length;
        for (final (label, type) in <(String, Type)>[
          ('Over All', OverallTab),
          ('Agencies', AgencyStatusBars),
          ('Working Group', WorkingGroupList),
          ('Categories', CategoryTotalsChart),
        ]) {
          final tab = find
              .descendant(
                of: find.byType(SharedDashboardCharts),
                matching: find.text(label),
              )
              .first;
          await tester.ensureVisible(tab);
          await tester.tap(tab);
          await tester.pumpAndSettle();
          expect(find.byType(type), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        expect(calls.length, beforeCharts);
        expect(
          tester
              .widget<CategoryTotalsChart>(find.byType(CategoryTotalsChart))
              .categories
              .first
              .total,
          105,
        );
        settings.setLanguage(AppLanguage.khmer);
        await tester.pumpAndSettle();
        expect(
          find.text('ផ្ទាំងគ្រប់គ្រងរួម'),
          findsNWidgets(role == AppModuleType.cdcSecretariat ? 1 : 2),
        );
        expect(find.text('៣៩១/៤២៤'), findsOneWidget);
        expect(find.text('អភិបាលកិច្ច'), findsOneWidget);
        expect(calls.length, beforeCharts);
        expect(tester.takeException(), isNull);
        settings.setLanguage(AppLanguage.english);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Filter'));
        await tester.tap(find.text('Filter'));
        await tester.pumpAndSettle();
        expect(calls.length, beforeCharts + 1);
        expect(calls.last.path, '/api/v1/dashboards/overview/live');
        final sheet = find.byType(ApiFilterSheet);
        Navigator.of(tester.element(sheet)).pop(
          FilterSelection({
            'local.status': {'SOLVED'},
          }),
        );
        await tester.pumpAndSettle();
        expect(find.text('391/391'), findsOneWidget);
        await selectScope(1);
        if (role == AppModuleType.cdcSecretariat) {
          expect(find.byKey(const ValueKey('dashboard-scope-2')), findsNothing);
        }
        expect(calls.last.path, '/api/v1/dashboards/pswg/live');
        expect(find.text('1/2'), findsNWidgets(2));
        await selectScope(2);
        expect(calls.last.path, '/api/v1/dashboards/overview/live');
        expect(
          find.text(
            role == AppModuleType.cdcSecretariat ? '391/424' : '391/391',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<PswgDataScope>(find.byType(PswgDataScope))
              .data
              .cards['inProgress'],
          role == AppModuleType.cdcSecretariat ? 33 : 0,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
