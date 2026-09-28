import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_report.dart';
import 'package:gpsf_app/screens/report/report_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  test('maps the current top-level progress report response', () {
    final report = ProgressReport({
      'id': 2,
      'title': 'ចំណងជើងរបាយការណ៍ **',
      'year': 2026,
      'semester': 'S2',
      'status': 'SENT',
      'activeDeadline': {'date': '2026-09-15'},
      'meetings': [
        {'meetingDate': '2026-09-03'},
        {'meetingDate': '2026-09-04'},
      ],
      'ministryDocuments': [
        {
          'ministry': {'name': 'MAFF'},
          'document': {'path': '/maff.pdf'},
        },
      ],
      'ministryAssignment': {'issues': 0},
    });
    expect(report.title, 'ចំណងជើងរបាយការណ៍ **');
    expect(report.deadline, DateTime.parse('2026-09-15'));
    expect(report.firstMeeting, DateTime.parse('2026-09-03'));
    expect(report.ministry, 'MAFF');
  });

  for (final role in [
    AppModuleType.privateSector,
    AppModuleType.lineMinistry,
  ]) {
    testWidgets('$role Progress Report uses the shared API', (tester) async {
      final requests = <String>[];
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    requests.add(request.url.path);
                    return http.Response.bytes(
                      utf8.encode(
                        jsonEncode({
                          'success': true,
                          'data': [
                            {
                              'id': 1,
                              'title': 'ចំណងជើងរបាយការណ៍ **',
                              'description': 'ការពិពណ៌នា **',
                              'year': 2026,
                              'semester': 'S2',
                              'status': 'SENT',
                              'activeDeadline': {'date': '2026-09-15'},
                              'deadlines': [
                                {'date': '2026-12-15'},
                                {'date': '2026-09-29'},
                              ],
                              'meetings': [
                                {'meetingDate': '2026-09-03'},
                                {'meetingDate': '2026-09-04'},
                              ],
                              'ministryDocuments': [
                                {
                                  'ministry': {'name': 'MAFF'},
                                  'document': {
                                    'path': '/maff.pdf',
                                    'name': 'MAFF.pdf',
                                  },
                                },
                              ],
                              'finalSemesterReport': {
                                'path': '/final.pdf',
                                'name': 'final.pdf',
                              },
                              'ministryAssignment': {
                                'issues': 3,
                                'attachment': {'path': '/solution.pdf'},
                              },
                            },
                          ],
                        }),
                      ),
                      200,
                    );
                  }),
                ),
              ),
            )
            ..setLanguage(AppLanguage.english)
            ..setModuleType(role);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: Scaffold(body: ReportScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(requests, ['/api/v1/progress-reports']);
      expect(find.text('ចំណងជើងរបាយការណ៍ **'), findsOneWidget);
    });
  }
}
