import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/private_sector/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/features/cdc_section/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/features/cdc_section/dashboard/overall_status_card.dart';
import 'package:gpsf_app/features/cefp/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/features/line_ministry/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/features/line_ministry/reports/reports_screen.dart';
import 'package:gpsf_app/features/cdc_secretariat/reports/reports_screen.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/pswg_live_dashboard.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  for (final role in AppModuleType.values) {
    testWidgets(
      '$role binds API data to the existing Working Group dashboard',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final hasPlenary = [
          AppModuleType.privateSector,
          AppModuleType.cdcSection,
          AppModuleType.cefp,
        ].contains(role);
        final requests = <String>[];
        final settings =
            AppSettingsController(
                authRepository: AuthRepository(
                  ApiClient(
                    client: MockClient((request) async {
                      requests.add(request.url.path);
                      expect(request.method, 'GET');
                      if (request.url.path.contains('/progress-reports')) {
                        return http.Response('{"data":[]}', 200);
                      }
                      expect(
                        request.url.path,
                        isIn([
                          '/api/v1/dashboards/pswg/live',
                          '/api/v1/dashboards/plenary/live',
                        ]),
                      );
                      return http.Response(
                        File(
                          request.url.path.contains('/plenary/')
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
              ..setModuleType(role);
        addTearDown(settings.dispose);
        final Widget screen = switch (role) {
          AppModuleType.cdcSection => const CdcSectionDashboardScreenView(),
          AppModuleType.cefp => const CefpDashboardScreenView(),
          AppModuleType.lineMinistry => const LineMinistryDashboardScreen(),
          _ => const DashboardPage(),
        };
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(home: Scaffold(body: screen)),
          ),
        );
        await tester.pumpAndSettle();
        if (hasPlenary) {
          expect(requests, ['/api/v1/dashboards/plenary/live']);
          expect(find.text('0/1'), findsNWidgets(2));
          expect(find.byType(PlenaryProgressStatusCard), findsOneWidget);
          final progress = tester.widget<PlenaryProgressStatusCard>(
            find.byType(PlenaryProgressStatusCard),
          );
          expect(progress.cards['midProgress'], 0);
          expect(progress.cards['earlyProgress'], 0);
          await tester.ensureVisible(find.byType(PlenaryProgressStatusCard));
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: find.byType(PlenaryProgressStatusCard),
              matching: find.text('0'),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
        await tester.ensureVisible(find.text('Working Group').first);
        await tester.tap(find.text('Working Group').first);
        await tester.pumpAndSettle();
        expect(find.byType(PswgDataScope), findsOneWidget);
        expect(find.byType(PlenaryProgressStatusCard), findsNothing);
        expect(requests.last, '/api/v1/dashboards/pswg/live');
        expect(requests.length, hasPlenary ? 2 : 1);
        expect(find.text('1/2'), findsNWidgets(2));
        expect(find.byType(ChoiceChip), findsNothing);
        if (hasPlenary) {
          await tester.ensureVisible(find.text('Plenary').first);
          await tester.tap(find.text('Plenary').first);
          await tester.pumpAndSettle();
          expect(requests.last, '/api/v1/dashboards/plenary/live');
          expect(find.text('0/1'), findsNWidgets(2));
          final previousRequests = requests.length;
          final breakdown = find.text('Working Group').last;
          await tester.ensureVisible(breakdown);
          await tester.tap(breakdown);
          await tester.pumpAndSettle();
          expect(requests.length, previousRequests);
          expect(find.text('Agriculture & Agro-Industry'), findsOneWidget);
          expect(
            tester
                .widget<PswgDataScope>(find.byType(PswgDataScope))
                .data
                .cards['totalIssues'],
            1,
          );
        }
        if (role == AppModuleType.cdcSecretariat) {
          expect(find.text('Agriculture & Agro-Industry'), findsOneWidget);
        }
        if (role == AppModuleType.lineMinistry ||
            role == AppModuleType.cdcSecretariat) {
          expect(find.text('Plenary'), findsNothing);
          expect(requests, ['/api/v1/dashboards/pswg/live']);
          await tester.pumpWidget(
            AppSettings(
              controller: settings,
              child: MaterialApp(
                home: Scaffold(
                  body: role == AppModuleType.lineMinistry
                      ? const LineMinistryReportsScreenView()
                      : const CdcSecretariatReportsScreenView(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Dashboard').first);
          await tester.tap(find.text('Dashboard').first);
          await tester.pumpAndSettle();
          expect(requests.last, '/api/v1/dashboards/plenary/live');
          expect(find.byType(SharedDashboardCharts), findsOneWidget);
          expect(find.byType(PlenaryProgressStatusCard), findsOneWidget);
          expect(find.text('0/1'), findsNWidgets(2));
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
