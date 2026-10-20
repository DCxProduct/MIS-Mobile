import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/screens/report/plenary_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  for (final failFirst in [false, true]) {
    testWidgets(
      'Plenary details load all decision pages and selected popup; retry=$failFirst',
      (tester) async {
        final paths = <String>[];
        var failed = false;
        final api = ApiClient(
          client: MockClient((request) async {
            paths.add(request.url.path);
            if (request.url.path == '/api/v1/plenaries/22') {
              if (failFirst && !failed) {
                failed = true;
                return http.Response('{}', 500);
              }
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'id': 22,
                    'meetingDate': '2026-10-19T00:00:00Z',
                    'deadline': '2027-01-02T00:00:00Z',
                    'status': 'Sent',
                    'statusCode': 'SENT',
                    'numberOfRgcDecisions': 2,
                    'documentReference': {
                      'path':
                          '/uploads/plenaries/97e8fc9e-ef27-4f39-b64f-fd0f955deaba.pdf?originalName=Approval%2022.pdf',
                    },
                  },
                }),
                200,
              );
            }
            expect(request.url.path, '/api/v1/rgc-decisions');
            expect(request.url.queryParameters['plenaryId'], '22');
            expect(request.url.queryParameters['limit'], '100');
            final page = int.parse(request.url.queryParameters['page']!);
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': [
                    {
                      'id': page,
                      'plenaryId': 22,
                      'meetingDate': '2026-10-19T00:00:00Z',
                      'category': 'Category $page',
                      'focalPerson': 'Person $page',
                      'stakeholder': {'name': 'Agency $page'},
                      'decision': '<p>Decision $page from API</p>',
                      'status': page == 1 ? 'In Progress' : 'Solved',
                      'verificationLink': 'https://example.com/decision-$page',
                    },
                  ],
                  'meta': {'totalPages': 2},
                },
              }),
              200,
            );
          }),
        );
        final settings = AppSettingsController(
          authRepository: AuthRepository(api),
        )..setLanguage(AppLanguage.english);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: const MaterialApp(
              home: PlenaryDetailScreen(title: 'Plenary', plenaryId: 22),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (failFirst) {
          expect(find.text('Retry'), findsOneWidget);
          expect(find.text('Decision 1 from API'), findsNothing);
          await tester.tap(find.text('Retry'));
          await tester.pumpAndSettle();
        }
        expect(find.textContaining('2027'), findsOneWidget);
        expect(find.textContaining('2026'), findsWidgets);
        expect(find.text('Approval 22.pdf'), findsOneWidget);
        expect(find.text('Decision 1 from API'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Decision 2 from API'), 100);
        expect(find.text('Decision 2 from API'), findsOneWidget);
        await tester.tap(find.text('Decision 2 from API'));
        await tester.pumpAndSettle();
        expect(find.text('Agency 2'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('https://example.com/decision-2'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('https://example.com/decision-2'), findsOneWidget);
        expect(
          paths.where((path) => path == '/api/v1/rgc-decisions').length,
          failFirst ? 4 : 2,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
