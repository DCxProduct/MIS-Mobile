import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decisions_repository.dart';
import 'package:gpsf_app/screens/report/report_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final response = {
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
          'issues': [
            {'attachment': '/uploads/issues/reference.pdf'},
          ],
        },
      ],
      'meta': {'total': 1, 'page': 1, 'limit': 10, 'totalPages': 1},
    },
  };

  test('maps the RGC decision response and nested issue link', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/rgc-decisions');
        return http.Response(jsonEncode(response), 200);
      }),
    );
    addTearDown(api.close);

    final decision = (await RgcDecisionsRepository(api).getDecisions()).single;
    expect(decision.agencyName, 'MAFF');
    expect(decision.category, 'Climate');
    expect(decision.statusCode, 'NOT_ADDRESSED');
    expect(decision.linkCount, 2);
  });

  testWidgets('Ministry RGC Decision tab uses the API', (tester) async {
    final settings =
        AppSettingsController(
            authRepository: AuthRepository(
              ApiClient(
                client: MockClient((request) async {
                  if (request.url.path == '/api/v1/progress-reports') {
                    return http.Response(
                      jsonEncode({'success': true, 'data': []}),
                      200,
                    );
                  }
                  return http.Response(jsonEncode(response), 200);
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
        child: const MaterialApp(home: Scaffold(body: ReportScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('RGC Decision'));
    await tester.pumpAndSettle();

    expect(find.text('MAFF'), findsOneWidget);
    expect(find.text('2 Link'), findsOneWidget);
  });
}
