import 'dart:io';
import 'package:gpsf_app/translations/app_language.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/screens/auth/login_screen.dart';
import 'package:gpsf_app/screens/account/profile_detail_screen.dart';
import 'package:gpsf_app/widgets/app_bottom_nav_bar.dart';
import 'package:gpsf_app/widgets/primary_button.dart';
import 'package:gpsf_app/features/cdc_secretariat/dashboard/agencies_tab.dart';

void main() {
  testWidgets('CDC account opens dashboard and displays its profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient(
            (request) async => http.Response(
              request.url.path == '/api/v1/meeting-requests'
                  ? File(
                      'test/fixtures/meeting_requests.json',
                    ).readAsStringSync()
                  : request.url.path == '/api/v1/working-group-issues/my'
                  ? File('test/fixtures/wg_issues.json').readAsStringSync()
                  : request.url.path ==
                        '/api/v1/working-group-issues/summary/my'
                  ? File(
                      'test/fixtures/wg_issue_summary.json',
                    ).readAsStringSync()
                  : request.url.path ==
                        '/api/v1/working-group-issues/issue-matrix'
                  ? File('test/fixtures/wg_issues.json').readAsStringSync()
                  : request.url.path ==
                        '/api/v1/working-group-issues/issue-matrix/summary'
                  ? File(
                      'test/fixtures/wg_issue_summary.json',
                    ).readAsStringSync()
                  : request.url.path == '/api/v1/dashboards/pswg/live'
                  ? File('test/fixtures/working_groups.json').readAsStringSync()
                  : request.url.path == '/api/v1/dashboards/plenary/live'
                  ? File('test/fixtures/plenary.json').readAsStringSync()
                  : request.url.path == '/api/v1/rgc-decisions/scorecard'
                  ? jsonEncode({
                      'success': true,
                      'data': {
                        'total': 1,
                        'byStatus': [
                          {'status': 'Not Addressed', 'count': 1},
                          {'status': 'In Progress', 'count': 0},
                          {'status': 'Solved', 'count': 0},
                        ],
                      },
                    })
                  : request.url.path == '/api/v1/rgc-decisions'
                  ? jsonEncode({
                      'success': true,
                      'data': {
                        'items': [
                          {
                            'id': 1,
                            'stakeholder': {'name': 'MAFF'},
                            'category': 'Climate',
                            'meetingDate': '2026-09-14T00:00:00.000Z',
                            'status': 'Not Addressed',
                            'statusCode': 'NOT_ADDRESSED',
                            'focalPerson': 'H.E. Mr. DITH TINA',
                            'verificationLink': 'https://example.com/verify',
                          },
                        ],
                      },
                    })
                  : jsonEncode({
                      'success': true,
                      'data': {
                        'user': {
                          'id': 1,
                          'email': 'cdcgpsf@gmail.com',
                          'name': 'CDC Secretariat',
                          'isActive': true,
                          'roles': [
                            {'name': 'cdc_secretariat'},
                          ],
                        },
                      },
                    }),
              200,
            ),
          ),
        ),
      ),
    );
    settings.setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'cdcgpsf@gmail.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(settings.moduleType, AppModuleType.cdcSecretariat);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1/2'), findsNWidgets(2));
    expect(find.text('(2)'), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsOneWidget);

    await tester.tap(find.text('Agencies'));
    await tester.pumpAndSettle();
    expect(find.byType(CdcSecretariatAgenciesTab), findsOneWidget);
    expect(find.text('Agencies'), findsNWidgets(2));

    await tester.tap(find.text('Working Group'));
    await tester.pumpAndSettle();
    expect(find.text('Rice and Paddy'), findsOneWidget);
    expect(find.text('Non-Bank Financial Services'), findsOneWidget);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Market Access'), findsOneWidget);
    await tester.ensureVisible(find.text('Market Access'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meeting'));
    await tester.pumpAndSettle();
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('Another meeting request'), findsOneWidget);
    expect(find.text('Submitted'), findsNothing);
    expect(find.text('Under Review'), findsOneWidget);
    expect(find.text('WG.Meeting'), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsOneWidget);

    await tester.tap(find.text('Issues'));
    await tester.pumpAndSettle();
    expect(find.text('WG Issues'), findsOneWidget);
    expect(find.text('MAFF'), findsOneWidget);
    expect(find.text('0/1'), findsNWidgets(2));
    await tester.tap(find.text('View Details').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Issues Matrix'));
    await tester.pumpAndSettle();
    expect(find.text('Second API issue'), findsOneWidget);
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report').last);
    await tester.pumpAndSettle();
    expect(find.text('0/1'), findsNWidgets(2));
    await tester.tap(find.text('Agencies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Working Group'));
    await tester.pumpAndSettle();
    expect(find.text('Law, Tax, and Governance'), findsOneWidget);
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('General'), findsOneWidget);
    await tester.tap(find.text('Plenaries'));
    await tester.pumpAndSettle();
    expect(find.text('19th G-PSF. Plenary'), findsOneWidget);
    expect(find.text('Apr 08, 2025'), findsOneWidget);
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RGC Decision').first);
    await tester.pumpAndSettle();
    expect(find.text('MPWT'), findsNWidgets(2));
    expect(find.text('Nov 13, 2023'), findsOneWidget);

    final context = tester.element(find.byType(AppBottomNavBar));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileDetailScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('CDC Secretariat'), findsOneWidget);
    expect(find.text('cdcgpsf@gmail.com'), findsOneWidget);
  });
}
