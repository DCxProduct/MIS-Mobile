import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/private_sector/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/features/private_sector/dashboard/tabs/overall_tab.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final fixture = File('test/fixtures/plenary.json').readAsStringSync();

  Future<void> mount(
    WidgetTester tester,
    Future<http.Response> Function(http.Request) handler,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/translations/dictionary')) {
          return http.Response('{}', 503);
        }
        return handler(request);
      }),
    );
    addTearDown(api.close);
    final settings = AppSettingsController(authRepository: AuthRepository(api))
      ..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(
          home: Scaffold(body: DashboardPage(initialScopeTab: 0)),
        ),
      ),
    );
  }

  for (final response in [
    ('HTTP error', '', 503),
    ('empty object', '{"success":true,"data":{}}', 200),
    ('null data', '{"success":true,"data":null}', 200),
  ]) {
    testWidgets('${response.$1} keeps dashboard without a reload notice', (
      tester,
    ) async {
      var calls = 0;
      final nextScope = Completer<http.Response>();
      await mount(tester, (_) async {
        calls++;
        if (calls == 1) return http.Response(response.$2, response.$3);
        return nextScope.future;
      });
      await tester.pumpAndSettle();
      expect(find.byType(SharedDashboardCharts), findsOneWidget);
      expect(find.byType(OverallTab), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Plenary'), findsWidgets);
      expect(find.text('Working Group'), findsWidgets);
      expect(find.text('Retry'), findsNothing);
      expect(
        find.text('Unable to load dashboard. Please try again.'),
        findsNothing,
      );
      expect(find.text('—'), findsWidgets);
      expect(find.text('0/0'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(
        find.byKey(const ValueKey('dashboard-scope-1')),
      );
      await tester.tap(find.byKey(const ValueKey('dashboard-scope-1')));
      await tester.pump();
      expect(find.byType(SharedDashboardCharts), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      nextScope.complete(http.Response(fixture, 200));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Retry'), findsNothing);
      expect(find.text('0/1'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('valid zero data keeps cards, charts and empty breakdowns', (
    tester,
  ) async {
    final empty = jsonDecode(fixture) as Map<String, dynamic>;
    final data = empty['data'] as Map<String, dynamic>;
    final cards = data['cards'] as Map<String, dynamic>;
    for (final key in cards.keys.toList()) {
      cards[key] = 0;
    }
    for (final key in ['byWorkingGroup', 'byPrimaryAgency', 'byCategory']) {
      data[key] = <Object>[];
    }
    await mount(tester, (_) async => http.Response(jsonEncode(empty), 200));
    await tester.pumpAndSettle();
    expect(find.byType(OverallTab), findsOneWidget);
    expect(find.text('0/0'), findsNWidgets(3));
    expect(find.text('Retry'), findsNothing);
    await tester.ensureVisible(find.text('Agencies').last);
    await tester.tap(find.text('Agencies').last);
    await tester.pumpAndSettle();
    expect(find.text('No issues found.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed scope does not prevent switching to another dashboard', (
    tester,
  ) async {
    await mount(tester, (request) async {
      return request.url.path.contains('/plenary/')
          ? http.Response('', 503)
          : http.Response(
              File('test/fixtures/working_groups.json').readAsStringSync(),
              200,
            );
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('dashboard-scope-1')));
    await tester.tap(find.byKey(const ValueKey('dashboard-scope-1')));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsNothing);
    expect(find.text('1/2'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
