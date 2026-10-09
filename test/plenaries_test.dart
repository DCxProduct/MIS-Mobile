import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/network/filter_catalog_repository.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/auth/data/auth_user.dart';
import 'package:gpsf_app/features/shared/meetings/data/plenaries_repository.dart';
import 'package:gpsf_app/features/shared/meetings/widgets/plenaries_loader.dart';
import 'package:gpsf_app/screens/report/report_screen.dart';
import 'package:gpsf_app/screens/report/plenary_detail_screen.dart';
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
  final sent = {
    ...(response['data'] as Map)['items'][0] as Map<String, dynamic>,
    'id': 5,
    'name': '21th',
    'status': 'Sent',
    'statusCode': 'SENT',
  };

  test(
    'sent-only plenaries keep pagination and override Draft filters',
    () async {
      final pages = <String>[];
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.url.queryParameters['statuses'], 'SENT');
          expect(request.url.queryParameters['ministryIds'], '1');
          final page = request.url.queryParameters['page']!;
          pages.add(page);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': page == '1'
                    ? (response['data'] as Map)['items']
                    : [sent],
                'meta': {'totalPages': 2},
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);
      final plenaries = await PlenariesRepository(api).getPlenaries(
        sentOnly: true,
        filters: {'statuses': 'DRAFT', 'ministryIds': '1'},
      );
      expect(plenaries.map((plenary) => plenary.id), [5]);
      expect(pages, ['1', '2']);
    },
  );

  test('Ministry plenary filter excludes Draft while CDC retains it', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/lookups/ministries')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'items': []},
            }),
            200,
          );
        }
        expect(request.url.path, '/api/v1/plenaries');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'success': true,
              'data': {
                'items': [...(response['data'] as Map)['items'] as List, sent],
                'meta': {'totalPages': 1},
              },
            }),
          ),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final catalog = FilterCatalogRepository(api);
    final ministry = await catalog.plenaries(sentOnly: true);
    expect(ministry.first.options.map((option) => option.value), ['SENT']);
    final cdc = await catalog.plenaries();
    expect(cdc.first.options.map((option) => option.value), ['DRAFT', 'SENT']);
  });

  for (final module in [
    AppModuleType.lineMinistry,
    AppModuleType.cdcSecretariat,
    AppModuleType.cefp,
  ]) {
    testWidgets('$module hides Draft only for Ministry and shows empty state', (
      tester,
    ) async {
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    expect(
                      request.url.queryParameters['statuses'],
                      module == AppModuleType.lineMinistry ? 'SENT' : null,
                    );
                    return http.Response.bytes(
                      utf8.encode(jsonEncode(response)),
                      200,
                    );
                  }),
                ),
              ),
            )
            ..setModuleType(module)
            ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: PlenariesLoader(
                builder: (items) => Column(
                  children: [for (final item in items) Text(item.status)],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Draft'),
        module == AppModuleType.lineMinistry ? findsNothing : findsOneWidget,
      );
      if (module == AppModuleType.lineMinistry) {
        expect(find.text('No plenaries found.'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

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
                  if (request.url.path == '/api/v1/plenaries/5') {
                    return http.Response.bytes(
                      utf8.encode(jsonEncode({'success': true, 'data': sent})),
                      200,
                    );
                  }
                  if (request.url.path == '/api/v1/rgc-decisions') {
                    expect(request.url.queryParameters['plenaryId'], '5');
                    expect(request.url.queryParameters['ministryOnly'], 'true');
                    expect(request.headers['x-user-id'], '77');
                    return http.Response(
                      jsonEncode({
                        'success': true,
                        'data': {
                          'items': [],
                          'meta': {'totalPages': 0},
                        },
                      }),
                      200,
                    );
                  }
                  if (request.url.path == '/api/v1/progress-reports') {
                    return http.Response(
                      jsonEncode({'success': true, 'data': []}),
                      200,
                    );
                  }
                  expect(request.url.queryParameters['statuses'], 'SENT');
                  return http.Response.bytes(
                    utf8.encode(
                      jsonEncode({
                        'success': true,
                        'data': {
                          ...(response['data'] as Map),
                          'items': [
                            ...(response['data'] as Map)['items'] as List,
                            sent,
                          ],
                        },
                      }),
                    ),
                    200,
                  );
                }),
              ),
            ),
          )
          ..setLanguage(AppLanguage.english)
          ..setModuleType(AppModuleType.lineMinistry);
    settings.setCurrentUser(
      const AuthUser(
        id: 77,
        email: 'ministry@example.com',
        name: 'Ministry user',
        isActive: true,
        roles: ['line_ministry'],
      ),
    );
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

    expect(find.text('វេទិការាជរដ្ឋាភិបាល-ផ្នែកឯកជន លើកទី 21'), findsNothing);
    expect(find.text('Draft'), findsNothing);
    expect(find.text('21th'), findsOneWidget);
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();
    expect(find.byType(PlenaryDetailScreen), findsOneWidget);
    expect(find.text('Sep 25, 2026'), findsOneWidget);
    expect(find.text('reference.pdf'), findsOneWidget);
    expect(find.text('June 07, 2025'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
