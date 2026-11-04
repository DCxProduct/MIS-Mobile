import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/filters/api_filter_sheet.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/auth/data/auth_user.dart';
import 'package:gpsf_app/features/line_ministry/meetings/meeting_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('moved Ministry meeting tabs keep separate API filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <Uri>[];
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((request) async {
            calls.add(request.url);
            return http.Response(
              jsonEncode({
                'success': true,
                'data': request.url.path.endsWith('meeting-requests')
                    ? []
                    : {
                        'items': [],
                        'meta': {'totalPages': 0},
                      },
              }),
              200,
            );
          }),
        ),
      ),
    )..setLanguage(AppLanguage.english);
    settings.currentUser = const AuthUser(
      id: 77,
      email: 'ministry@example.com',
      name: 'Ministry',
      isActive: true,
    );
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(
          home: Scaffold(body: LineMinistryMeetingScreenView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls.single.path, '/api/v1/meeting-requests');

    for (final (label, resource, page, key, value) in [
      ('Plenary', 'plenaries', 'plenary_plenaries', 'ministryIds', '7'),
      (
        'RGC Decision',
        'rgc-decisions',
        'plenary_rgc_decisions',
        'plenaryId',
        '9',
      ),
    ]) {
      await tester.ensureVisible(find.text(label).last);
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(calls.last.path, '/api/v1/$resource');
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      final sheet = find.byType(ApiFilterSheet);
      expect(tester.widget<ApiFilterSheet>(sheet).translationPage, page);
      expect(tester.widget<ApiFilterSheet>(sheet).initial.count, 0);
      Navigator.of(tester.element(sheet)).pop(
        FilterSelection({
          key: {value},
        }),
      );
      await tester.pumpAndSettle();
      expect(calls.last.path, '/api/v1/$resource');
      expect(calls.last.queryParameters[key], value);
    }
    await tester.ensureVisible(find.text('Plenary').last);
    await tester.tap(find.text('Plenary').last);
    await tester.pumpAndSettle();
    expect(calls.last.queryParameters['ministryIds'], '7');
    expect(calls.last.queryParameters['plenaryId'], isNull);
    expect(calls.last.queryParameters['statuses'], 'SENT');
    expect(tester.takeException(), isNull);
  });
}
