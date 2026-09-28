import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/text/html_text.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/issues/data/issues_repository.dart';
import 'package:gpsf_app/features/shared/issues/widgets/wg_issues_list.dart';
import 'package:gpsf_app/screens/issues/issues_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final fixture = File('test/fixtures/wg_issues.json').readAsStringSync();
  final title = (jsonDecode(fixture)['data']['items'][0]['title']) as String;
  test(
    'maps returned records, null relations, ordered agencies and deduplicated links',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/working-group-issues/my');
          return http.Response.bytes(
            utf8.encode(jsonEncode(jsonDecode(fixture))),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final items = await IssuesRepository(api).getMyWorkingGroupIssues();
      expect(items.map((item) => item.id), [12, 11]);
      expect(items.first.title, title);
      expect(items.first.category, 'Regulation');
      expect(items.first.agency, 'MAFF');
      expect(items.first.statusCode, 'SOLVED');
      expect(items.first.attachmentCount, 1);
      expect(items.first.linkCount, 3);
      expect(items.first.description, isNot(contains('<p>')));
      expect(items.first.description, contains('\n'));
      expect(items.last.meetingDate, isNull);
      expect(items.last.category, isEmpty);
      expect(items.last.description, 'Plain description & details');
      expect(items.last.statusName, 'Draft');
    },
  );

  test('HTML preview decodes entities and excludes scripts', () {
    expect(
      htmlToPlainText(
        '<p>First &amp; second</p><script>secret()</script><p>Next</p>',
      ),
      'First & second\nNext',
    );
  });

  test(
    'rejects a malformed list rather than silently using demo issues',
    () async {
      final api = ApiClient(
        client: MockClient(
          (_) async =>
              http.Response('{"success":true,"data":{"items":{}}}', 200),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        IssuesRepository(api).getMyWorkingGroupIssues(),
        throwsA(isA<ApiException>()),
      );
    },
  );

  for (final role in AppModuleType.values) {
    testWidgets('$role shows each API record below summary cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var listCalls = 0;
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    if (request.url.path.endsWith('/summary/my')) {
                      return http.Response(
                        File(
                          'test/fixtures/wg_issue_summary.json',
                        ).readAsStringSync(),
                        200,
                      );
                    }
                    listCalls++;
                    return http.Response.bytes(
                      utf8.encode(jsonEncode(jsonDecode(fixture))),
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
      expect(find.text(title), findsOneWidget);
      expect(find.text('Second API issue'), findsOneWidget);
      expect(find.text('Regulation'), findsOneWidget);
      expect(
        find.text('Draft'),
        role == AppModuleType.lineMinistry ? findsNothing : findsOneWidget,
      );
      expect(listCalls, 1);
      await tester.ensureVisible(find.text(title));
      if (role == AppModuleType.cdcSecretariat) {
        await tester.ensureVisible(find.text('View Details').first);
        await tester.tap(find.text('View Details').first);
      } else {
        await tester.tap(find.text(title));
      }
      await tester.pumpAndSettle();
      expect(find.text('ស្នើសុំអន្តរាគមន៍ជួយប្រមូលទិញត្រី'), findsOneWidget);
    });
  }

  testWidgets('retry returns empty state without demo cards', (tester) async {
    var calls = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((_) async {
            calls++;
            return calls == 1
                ? http.Response('', 502)
                : http.Response('{"success":true,"data":{"items":[]}}', 200);
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
            body: WgIssuesList(itemBuilder: (issue) => Text(issue.title)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No issues found.'), findsOneWidget);
    expect(calls, 2);
  });
}
