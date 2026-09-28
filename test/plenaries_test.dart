import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/meetings/data/plenaries_repository.dart';
import 'package:gpsf_app/screens/report/report_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final response = {
    'success': true,
    'data': {
      'items': [
        {
          'id': 4,
          'name': 'វេទិការាជរដ្ឋាភិបាល-ផ្នែកឯកជន លើកទី 21',
          'meetingDate': '2026-09-25T06:00:00.000Z',
          'deadline': '2026-09-30T06:00:00.000Z',
          'documentReference': '/uploads/plenaries/reference.pdf',
          'status': 'Draft',
          'statusCode': 'DRAFT',
          'numberOfRgcDecisions': 0,
          'ministries': [
            {'id': 1, 'name': 'MAFF'},
          ],
        },
      ],
      'meta': {'total': 1, 'page': 1, 'limit': 10, 'totalPages': 1},
    },
  };

  test('maps the paginated plenary response', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/plenaries');
        return http.Response.bytes(utf8.encode(jsonEncode(response)), 200);
      }),
    );
    addTearDown(api.close);

    final plenary = (await PlenariesRepository(api).getPlenaries()).single;
    expect(plenary.id, 4);
    expect(plenary.name, contains('21'));
    expect(plenary.statusCode, 'DRAFT');
    expect(plenary.numberOfRgcDecisions, 0);
    expect(plenary.ministryCount, 1);
    expect(plenary.attachmentCount, 1);
  });

  testWidgets('Ministry Plenary tab uses the API', (tester) async {
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
                  return http.Response.bytes(
                    utf8.encode(jsonEncode(response)),
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
        child: const MaterialApp(home: Scaffold(body: ReportScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plenary'));
    await tester.pumpAndSettle();

    expect(find.text('វេទិការាជរដ្ឋាភិបាល-ផ្នែកឯកជន លើកទី 21'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
