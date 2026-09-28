import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/dashboard/data/dashboard_repository.dart';
import 'package:gpsf_app/features/private_sector/dashboard/tabs/working_group_tab.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final fixture = File('test/fixtures/working_groups.json').readAsStringSync();

  test(
    'GET parses every working group in server order including zero counts',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/dashboards/pswg/live');
          return http.Response(fixture, 200);
        }),
      );
      addTearDown(api.close);
      final rows = await DashboardRepository(api).getWorkingGroups();
      expect(rows.length, 14);
      expect(rows.first.id, 14);
      expect(rows.first.name, 'Agriculture & Agro-Industry');
      expect(
        [
          rows.first.total,
          rows.first.solved,
          rows.first.inProgress,
          rows.first.notAddressed,
        ],
        [2, 1, 1, 0],
      );
      expect(rows.last.total, 0);
    },
  );

  test(
    'Plenary uses its own endpoint and preserves zero progress values',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/dashboards/plenary/live');
          return http.Response(
            File('test/fixtures/plenary.json').readAsStringSync(),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final data = await DashboardRepository(
        api,
      ).getLiveDashboard(scope: DashboardScope.plenary);
      expect(data.cards['totalIssues'], 1);
      expect(data.cards['solved'], 0);
      expect(data.cards['notAddressed'], 1);
      expect(data.cards['midProgress'], 0);
      expect(data.workingGroups.first.notAddressed, 1);
    },
  );

  test(
    'missing or malformed rows fail rather than display invented zeroes',
    () async {
      for (final body in [
        '{"success":true,"data":{}}',
        '{"success":true,"data":{"byWorkingGroup":[{"workingGroupName":"Missing counts"}]}}',
      ]) {
        final api = ApiClient(
          client: MockClient((_) async => http.Response(body, 200)),
        );
        addTearDown(api.close);
        await expectLater(
          DashboardRepository(api).getWorkingGroups(),
          throwsA(isA<ApiException>()),
        );
      }
    },
  );

  testWidgets(
    'loads once per mount, retries failure, handles empty data on remount',
    (tester) async {
      var calls = 0;
      final initial = Completer<http.Response>();
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((_) async {
              calls++;
              if (calls == 1) return initial.future;
              if (calls == 2) return http.Response(fixture, 200);
              return http.Response(
                '{"success":true,"data":{"byWorkingGroup":[]}}',
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
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: WorkingGroupTab()),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      initial.complete(http.Response('', 502));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to load working groups. Please try again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Agriculture & Agro-Industry'), findsOneWidget);
      expect(find.text('Rice and Paddy'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      settings.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: Scaffold(body: WorkingGroupTab())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No working groups available.'), findsOneWidget);
      expect(calls, 3);
    },
  );
}
