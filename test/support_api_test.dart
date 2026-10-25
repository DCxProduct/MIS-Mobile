import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/screens/account/support_center_screen.dart';
import 'package:gpsf_app/screens/account/support_repository.dart';

void main() {
  http.Response response(String email, String telegram) => http.Response(
    jsonEncode({
      'success': true,
      'data': {'email': email, 'telegramUrl': telegram},
    }),
    200,
  );

  testWidgets('support loads live contacts, launches links and refreshes', (
    tester,
  ) async {
    var calls = 0;
    final launched = <String>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'launch') {
        launched.add((call.arguments as Map)['url'] as String);
      }
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((request) async {
            expect(request.method, 'GET');
            expect(request.url.path, '/api/v1/support');
            expect(request.headers['Cache-Control'], 'no-cache');
            calls++;
            return response(
              calls == 1 ? 'helpdesk@cdc.gov.kh' : 'updated@cdc.gov.kh',
              'https://t.me/cdc_cambodia',
            );
          }),
        ),
      ),
    );
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: SupportCenterScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ជំនួយគាំទ្រ'), findsOneWidget);
    expect(find.text('support@example.com'), findsNothing);
    expect(find.text('helpdesk@cdc.gov.kh'), findsOneWidget);
    await tester.tap(find.text('helpdesk@cdc.gov.kh'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(launched, [
      'mailto:helpdesk@cdc.gov.kh',
      'https://t.me/cdc_cambodia',
    ]);
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('updated@cdc.gov.kh'), findsOneWidget);
  });

  testWidgets('failed fetch retries without showing fake contacts', (
    tester,
  ) async {
    var calls = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient(
            (_) async => ++calls == 1
                ? http.Response('{"success":false}', 500)
                : response('helpdesk@cdc.gov.kh', 'https://t.me/cdc_cambodia'),
          ),
        ),
      ),
    );
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: SupportCenterScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('support@example.com'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(find.text('helpdesk@cdc.gov.kh'), findsOneWidget);
    expect(calls, 2);
  });

  test('invalid contact payloads are rejected', () async {
    for (final data in [
      response('', 'https://t.me/cdc_cambodia'),
      response('helpdesk@cdc.gov.kh', 'javascript:alert(1)'),
      http.Response('{"success":true,"data":{}}', 200),
    ]) {
      final repository = SupportRepository(
        ApiClient(client: MockClient((_) async => data)),
      );
      await expectLater(repository.fetch(), throwsA(isA<ApiException>()));
    }
  });
}
