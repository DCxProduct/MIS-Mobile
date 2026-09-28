import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/issues/data/issues_repository.dart';
import 'package:gpsf_app/features/shared/issues/widgets/wg_issue_summary_loader.dart';
import 'package:gpsf_app/screens/issues/issues_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final fixture = File(
    'test/fixtures/wg_issue_summary.json',
  ).readAsStringSync();
  test(
    'my WG summary uses supplied values even when status counts do not sum to total',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/working-group-issues/summary/my');
          return http.Response(fixture, 200);
        }),
      );
      addTearDown(api.close);
      final summary = await IssuesRepository(api).getMyWorkingGroupSummary();
      expect(summary.totalIssues, 12);
      expect(summary.solved, 1);
      expect(summary.inProgress, 3);
      expect(summary.notAddressed, 0);
      expect(summary.totalPrimaryAgencies, 1);
    },
  );

  test(
    'malformed summary is rejected instead of displaying demo counts',
    () async {
      final api = ApiClient(
        client: MockClient(
          (_) async =>
              http.Response('{"success":true,"data":{"totalIssues":12}}', 200),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        IssuesRepository(api).getMyWorkingGroupSummary(),
        throwsA(isA<ApiException>()),
      );
    },
  );

  for (final role in AppModuleType.values) {
    testWidgets('$role WG Issues populates existing summary cards only', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var requests = 0;
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    if (request.url.path == '/api/v1/working-group-issues/my') {
                      return http.Response(
                        File('test/fixtures/wg_issues.json').readAsStringSync(),
                        200,
                      );
                    }
                    if (request.url.path.endsWith('/summary/my') ||
                        request.url.path.endsWith('/issue-matrix/summary')) {
                      requests++;
                      return http.Response(fixture, 200);
                    }
                    return http.Response(
                      File('test/fixtures/wg_issues.json').readAsStringSync(),
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
          child: const MaterialApp(home: Scaffold(body: IssuesScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
      expect(find.text('1/12'), findsOneWidget);
      expect(find.text('3/12'), findsOneWidget);
      expect(find.text('0/12'), findsOneWidget);
      expect(requests, 1);
      settings.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(requests, 1);
      await tester.tap(find.text('Issues Matrix').last);
      await tester.pumpAndSettle();
      expect(find.byType(WgIssueSummaryLoader), findsOneWidget);
      expect(requests, 2);
    });
  }

  testWidgets('private-sector Issues Matrix switches to matrix API endpoints', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final paths = <String>[];
    final settings =
        AppSettingsController(
            authRepository: AuthRepository(
              ApiClient(
                client: MockClient((request) async {
                  paths.add(request.url.path);
                  if (request.url.path.endsWith('/summary/my')) {
                    return http.Response(fixture, 200);
                  }
                  if (request.url.path.endsWith('/issue-matrix/summary')) {
                    return http.Response(
                      jsonEncode({
                        'success': true,
                        'data': {
                          'totalIssues': 5,
                          'solved': 1,
                          'inProgress': 3,
                          'notAddressed': 0,
                          'totalPrimaryAgencies': 1,
                        },
                      }),
                      200,
                    );
                  }
                  return http.Response(
                    File('test/fixtures/wg_issues.json').readAsStringSync(),
                    200,
                  );
                }),
              ),
            ),
          )
          ..setLanguage(AppLanguage.english)
          ..setModuleType(AppModuleType.privateSector);
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: Scaffold(body: IssuesScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(paths, contains('/api/v1/working-group-issues/summary/my'));
    expect(paths, contains('/api/v1/working-group-issues/my'));

    await tester.tap(find.text('Issues Matrix').last);
    await tester.pumpAndSettle();

    expect(
      paths,
      contains('/api/v1/working-group-issues/issue-matrix/summary'),
    );
    expect(paths, contains('/api/v1/working-group-issues/issue-matrix'));
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('loading and retry keep failures out of summary cards', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var calls = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((_) async {
            calls++;
            if (calls == 1) return pending.future;
            return http.Response(
              '{"success":true,"data":{"totalIssues":0,"solved":0,"inProgress":0,"notAddressed":0,"totalPrimaryAgencies":0}}',
              200,
            );
          }),
        ),
      ),
    )..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: WgIssueSummaryLoader(
              builder: (summary) => Text('Total: ${summary.totalIssues}'),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(http.Response('', 502));
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to load issue summary'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Total: 0'), findsOneWidget);
    expect(calls, 2);
  });
}
