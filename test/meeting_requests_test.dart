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
import 'package:gpsf_app/features/shared/meetings/data/meeting_requests_repository.dart';
import 'package:gpsf_app/features/shared/meetings/widgets/meeting_requests_list.dart';
import 'package:gpsf_app/screens/meeting/meeting_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final fixture = File(
    'test/fixtures/meeting_requests.json',
  ).readAsStringSync();
  test(
    'maps direct array, nested string attachments, Khmer and missing fields',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/meeting-requests');
          return http.Response.bytes(
            utf8.encode(jsonEncode(jsonDecode(fixture))),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final items = await MeetingRequestsRepository(api).getRequests();
      expect(items.map((item) => item.id), [4, 3]);
      expect(items.first.title, 'សំណើសុំរៀបចំកិច្ចប្រជុំ');
      expect(items.first.attachmentCount, 2);
      expect(items.first.issuesCount, 2);
      expect(items.first.description, 'Meeting description & details');
      expect(items.first.issues.first.attachmentCount, 1);
      expect(items.first.issues.last.recommendation, 'Nested recommendation');
      expect(items.last.meetingDate, isNull);
      expect(items.last.attachmentCount, 0);
    },
  );
  for (final role in AppModuleType.values) {
    testWidgets('$role loads meeting cards and nested issue details', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    calls++;
                    expect(request.url.path, '/api/v1/meeting-requests');
                    return http.Response(fixture, 200);
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
          child: const MaterialApp(home: Scaffold(body: MeetingScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Another meeting request'), findsOneWidget);
      expect(find.text('2 Attachments'), findsOneWidget);
      await tester.tap(find.text('សំណើសុំរៀបចំកិច្ចប្រជុំ'));
      await tester.pumpAndSettle();
      expect(find.text('Meeting description & details'), findsOneWidget);
      expect(find.text('meeting_request_latter.pdf'), findsOneWidget);
      await tester.tap(find.text('All Issues'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Second meeting issue'));
      await tester.tap(find.text('Second meeting issue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nested recommendation', findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('failed request retries and empty response has no demo cards', (
    tester,
  ) async {
    var calls = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((_) async {
            calls++;
            return calls == 1
                ? http.Response('{}', 500)
                : http.Response('{"success":true,"data":[]}', 200);
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
            body: MeetingRequestsList(itemBuilder: (item) => Text(item.title)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('No meeting requests found.'), findsOneWidget);
  });
}
