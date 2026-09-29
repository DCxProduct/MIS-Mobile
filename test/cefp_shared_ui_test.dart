import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/config/module_repositories.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_section/reports/reports_screen.dart';
import 'package:gpsf_app/features/cefp/reports/reports_screen.dart';
import 'package:gpsf_app/features/cdc_section/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/features/cdc_section/issues/cdc_issues_matrix_screen.dart';
import 'package:gpsf_app/features/cdc_section/issues/issues_screen.dart';
import 'package:gpsf_app/features/private_sector/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/widgets/app_bottom_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'CEFP shell opens the CDC layouts and keeps its module identity',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = AuthRepository(
        ApiClient(
          client: MockClient((_) async {
            throw StateError('Sample navigation must not request API data');
          }),
        ),
      );
      final user = await auth.login('cefp@gmail.com', '12345678');
      final settings = AppSettingsController(authRepository: auth)
        ..setLanguage(AppLanguage.english)
        ..setCurrentUser(user);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(CdcSectionDashboardScreenView), findsOneWidget);
      for (final scope in [0, 1]) {
        final viewport = find.byKey(const ValueKey('cdc-dashboard-scroll'));
        final scroll = tester.state<ScrollableState>(
          find
              .descendant(of: viewport, matching: find.byType(Scrollable))
              .first,
        );
        scroll.position.jumpTo(0);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('cdc-dashboard-main-$scope')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Agencies'));
        await tester.tap(find.text('Agencies'));
        await tester.pumpAndSettle();
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        final navTop = tester.getRect(find.byType(AppBottomNavBar)).top;
        expect(tester.getRect(viewport).bottom, lessThanOrEqualTo(navTop));
        expect(tester.getRect(find.text('MPTC')).bottom, lessThan(navTop));
      }
      await tester.tap(find.text('CEFP Issues'));
      await tester.pumpAndSettle();
      expect(find.byType(CdcSectionIssuesMatrixScreen), findsOneWidget);
      expect(find.text('CEFP Issues Matrix'), findsOneWidget);
      expect(find.text('CDC Issues'), findsNothing);
      expect(find.text('CDC Issues Matrix'), findsNothing);
      settings.setLanguage(AppLanguage.khmer);
      await tester.pumpAndSettle();
      expect(find.text('តារាងបញ្ហា CEFP'), findsOneWidget);
      expect(find.text('បញ្ហា CEFP'), findsOneWidget);
      settings.setLanguage(AppLanguage.english);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Issues'));
      await tester.pumpAndSettle();
      expect(find.byType(CdcSectionIssuesScreenView), findsOneWidget);
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(find.byType(CdcSectionReportsScreenView), findsOneWidget);
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(settings.moduleType, AppModuleType.cefp);
      expect(tester.takeException(), isNull);
    },
  );

  test('CEFP repositories stay separate from CDC while sharing UI', () async {
    final requests = <String>[];
    ApiClient api(String module) => ApiClient(
      baseUrl: 'https://$module.example/api/',
      client: MockClient((request) async {
        requests.add(request.url.host);
        return http.Response('{"success":true,"data":{"items":[]}}', 200);
      }),
    );
    final cefpApi = api('cefp');
    final cefp = ModuleRepositories(apiClient: cefpApi);
    final settings = AppSettingsController(
      authRepository: AuthRepository(api('cdc')),
      moduleRepositories: {AppModuleType.cefp: cefp},
    );
    addTearDown(settings.dispose);
    addTearDown(cefpApi.close);
    settings.setModuleType(AppModuleType.cdcSection);
    final cdcIssues = settings.issues;
    await settings.issues.getIssueMatrix();
    settings.setModuleType(AppModuleType.cefp);
    expect(settings.dashboard, same(cefp.dashboard));
    expect(settings.issues, same(cefp.issues));
    expect(settings.meetingRequests, same(cefp.meetingRequests));
    expect(settings.meetings, same(cefp.meetings));
    expect(settings.meetingSummaries, same(cefp.meetingSummaries));
    expect(settings.progressReports, same(cefp.progressReports));
    expect(settings.plenaries, same(cefp.plenaries));
    expect(settings.rgcDecisions, same(cefp.rgcDecisions));
    await settings.issues.getIssueMatrix();
    settings.setModuleType(AppModuleType.cdcSection);
    expect(settings.issues, same(cdcIssues));
    expect(requests, ['cdc.example', 'cefp.example']);
  });

  testWidgets('CEFP report renders CDC UI without recursive module routing', (
    tester,
  ) async {
    final settings = AppSettingsController()
      ..setLanguage(AppLanguage.english)
      ..setModuleType(AppModuleType.cefp);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: Scaffold(body: CefpReportsScreenView())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CdcSectionReportsScreenView), findsOneWidget);
    expect(find.text('RGC Decision'), findsOneWidget);
    expect(settings.moduleType, AppModuleType.cefp);
    expect(tester.takeException(), isNull);
  });
}
