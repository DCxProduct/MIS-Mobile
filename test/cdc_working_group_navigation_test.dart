import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/filters/api_filter_sheet.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_secretariat/plenary/plenary_screen.dart';
import 'package:gpsf_app/features/private_sector/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/widgets/app_bottom_nav_bar.dart';
import 'package:gpsf_app/widgets/app_header.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final language in AppLanguage.values) {
    testWidgets('$language CDC groups load the moved pages from their own APIs', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final code = language == AppLanguage.khmer ? 'km' : 'en';
      final labels = Map<String, String>.from(
        jsonDecode(
              File(
                'test/fixtures/cdcgpsf_translation_labels.json',
              ).readAsStringSync(),
            )[code]
            as Map,
      );
      final calls = <Uri>[];
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    final path = request.url.path;
                    if (path.endsWith('translations/dictionary')) {
                      return http.Response(
                        jsonEncode({
                          'success': true,
                          'data': {
                            'success': true,
                            'data': {
                              'module': 'cdcgpsf',
                              'language': code,
                              'page': null,
                              'translations': labels,
                            },
                          },
                        }),
                        200,
                        headers: {
                          'content-type': 'application/json; charset=utf-8',
                        },
                      );
                    }
                    calls.add(request.url);
                    final fixture = switch (path) {
                      '/api/v1/dashboards/pswg/live' => 'working_groups.json',
                      '/api/v1/dashboards/plenary/live' =>
                        'plenary_live_report.json',
                      '/api/v1/working-group-issues/issue-matrix/summary' =>
                        'wg_issue_summary.json',
                      _ => null,
                    };
                    if (fixture != null) {
                      return http.Response(
                        File('test/fixtures/$fixture').readAsStringSync(),
                        200,
                      );
                    }
                    if (path ==
                        '/api/v1/working-group-issues/issue-matrix/filter-options') {
                      return http.Response(
                        jsonEncode({
                          'success': true,
                          'data': {
                            'categories': [],
                            'statuses': [],
                            'governmentAgencies': [],
                            'years': [],
                          },
                        }),
                        200,
                      );
                    }
                    if (path == '/api/v1/rgc-decisions/scorecard') {
                      return http.Response(
                        jsonEncode({
                          'success': true,
                          'data': {'total': 0, 'byStatus': []},
                        }),
                        200,
                      );
                    }
                    return http.Response(
                      jsonEncode({'success': true, 'data': []}),
                      200,
                    );
                  }),
                ),
              ),
            )
            ..setModuleType(AppModuleType.cdcSecretariat)
            ..setLanguage(language);
      addTearDown(settings.dispose);
      await settings.loadTranslations();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      final nav = find.byType(AppBottomNavBar);
      expect(
        find.descendant(of: nav, matching: find.byType(InkWell)),
        findsNWidgets(5),
      );
      expect(
        find.descendant(
          of: nav,
          matching: find.text(labels['dashboard.working_group']!),
        ),
        findsOneWidget,
      );
      expect(calls.map((uri) => uri.path), ['/api/v1/dashboards/pswg/live']);
      expect(find.byType(AppHeader), findsOneWidget);

      for (final (index, key, endpoint) in [
        (1, 'meeting_requests.title', '/api/v1/meeting-requests'),
        (2, 'meeting_calendar.title', '/api/v1/meetings'),
        (3, 'meeting_summary.title', '/api/v1/meeting-summaries'),
        (4, 'issue_matrix.title', '/api/v1/working-group-issues/issue-matrix'),
      ]) {
        final tab = find.byKey(ValueKey('cdc-working-group-tab-$index'));
        expect(
          find.descendant(of: tab, matching: find.text(labels[key]!)),
          findsOneWidget,
        );
        await tester.ensureVisible(tab);
        await tester.tap(tab);
        await tester.pumpAndSettle();
        expect(
          calls.any((uri) => uri.path == endpoint),
          isTrue,
          reason: endpoint,
        );
        expect(find.byType(AppHeader), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (index != 2) {
          await tester.tap(find.byIcon(Icons.filter_list).last);
          await tester.pumpAndSettle();
          final sheet = find.byType(ApiFilterSheet);
          expect(
            tester.widget<ApiFilterSheet>(sheet).translationPage,
            {
              1: 'meeting_requests',
              3: 'meeting_summary',
              4: 'issue_matrix',
            }[index],
          );
          Navigator.of(tester.element(sheet)).pop(FilterSelection());
          await tester.pumpAndSettle();
        }
      }
      final previousRequestCount = calls
          .where((uri) => uri.path == '/api/v1/meeting-requests')
          .length;
      final requestTab = find.byKey(const ValueKey('cdc-working-group-tab-1'));
      await tester.ensureVisible(requestTab);
      await tester.tap(requestTab);
      await tester.pumpAndSettle();
      expect(
        calls.where((uri) => uri.path == '/api/v1/meeting-requests').length,
        previousRequestCount,
      );

      // The new Plenary destination owns the three former report tabs.
      await tester.tap(
        find.descendant(of: nav, matching: find.byType(InkWell)).at(1),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AppBottomNavBar>(nav).selectedIndex, 1);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('cdc-plenary-tabs')),
          matching: find.byType(InkWell),
        ),
        findsNWidgets(3),
      );
      for (final (index, key, endpoint, page) in [
        (
          0,
          'plenary_dashboard.title',
          '/api/v1/dashboards/plenary/live',
          'dashboard_plenary',
        ),
        (
          1,
          'plenary_plenaries.title',
          '/api/v1/plenaries',
          'plenary_plenaries',
        ),
        (
          2,
          'issue_matrix_rgc_decision.rgc.page.title',
          '/api/v1/rgc-decisions/cdc-gpsf',
          'cdc_rgc',
        ),
      ]) {
        final tab = find.byKey(ValueKey('cdc-plenary-tab-$index'));
        await tester.ensureVisible(tab);
        await tester.tap(tab);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(CdcPlenaryScreen),
            matching: find.text(labels[key]!),
          ),
          findsNWidgets(2),
        );
        expect(calls.any((uri) => uri.path == endpoint), isTrue);
        await tester.tap(find.byIcon(Icons.filter_list).last);
        await tester.pumpAndSettle();
        final sheet = find.byType(ApiFilterSheet);
        expect(tester.widget<ApiFilterSheet>(sheet).translationPage, page);
        Navigator.of(tester.element(sheet)).pop();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(
        calls.any((uri) => uri.path == '/api/v1/progress-reports'),
        isFalse,
      );

      // Reports has just progress reports and its original filter context.
      await tester.tap(
        find.descendant(of: nav, matching: find.byType(InkWell)).at(3),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AppBottomNavBar>(nav).selectedIndex, 3);
      expect(find.byKey(const ValueKey('cdc-plenary-tabs')), findsNothing);
      expect(find.byKey(const ValueKey('cdc-report-tabs')), findsNothing);
      expect(
        calls.any((uri) => uri.path == '/api/v1/progress-reports'),
        isTrue,
      );
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      final reportFilter = find.byType(ApiFilterSheet);
      expect(
        tester.widget<ApiFilterSheet>(reportFilter).translationPage,
        'progress_report',
      );
      Navigator.of(tester.element(reportFilter)).pop();
      await tester.pumpAndSettle();

      // Issues follows Web: Issue Matrix first, then RGC Decision.
      await tester.tap(
        find.descendant(of: nav, matching: find.byType(InkWell)).at(2),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cdc-working-group-tab-0')),
        findsNothing,
      );
      final issueMatrix = find.byKey(const ValueKey('cdc-issues-tab-matrix'));
      final rgcDecision = find.byKey(const ValueKey('cdc-issues-tab-rgc'));
      expect(issueMatrix, findsOneWidget);
      expect(rgcDecision, findsOneWidget);
      expect(
        tester.getCenter(issueMatrix).dx,
        lessThan(tester.getCenter(rgcDecision).dx),
      );
      expect(find.text(labels['issue_matrix.title']!), findsNWidgets(2));
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      var issueFilter = find.byType(ApiFilterSheet);
      expect(
        tester.widget<ApiFilterSheet>(issueFilter).translationPage,
        'issue_matrix',
      );
      Navigator.of(tester.element(issueFilter)).pop(
        FilterSelection({
          'year': {'2027'},
        }),
      );
      await tester.pumpAndSettle();
      expect(
        calls
            .lastWhere(
              (uri) => uri.path == '/api/v1/working-group-issues/issue-matrix',
            )
            .queryParameters['year'],
        '2027',
      );

      await tester.tap(rgcDecision);
      await tester.pumpAndSettle();
      expect(
        find.text(labels['issue_matrix_rgc_decision.rgc.page.title']!),
        findsNWidgets(2),
      );
      expect(
        calls.any((uri) => uri.path == '/api/v1/rgc-decisions/cdc-gpsf'),
        isTrue,
      );
      expect(
        calls
            .lastWhere((uri) => uri.path == '/api/v1/rgc-decisions/cdc-gpsf')
            .queryParameters['year'],
        isNull,
      );
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      issueFilter = find.byType(ApiFilterSheet);
      expect(
        tester.widget<ApiFilterSheet>(issueFilter).translationPage,
        'cdc_rgc',
      );
      expect(tester.widget<ApiFilterSheet>(issueFilter).initial.count, 0);
      Navigator.of(tester.element(issueFilter)).pop();
      await tester.pumpAndSettle();

      await tester.tap(issueMatrix);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      issueFilter = find.byType(ApiFilterSheet);
      expect(
        tester.widget<ApiFilterSheet>(issueFilter).initial.toQuery()['year'],
        '2027',
      );
      Navigator.of(tester.element(issueFilter)).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
