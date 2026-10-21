import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/screens/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:gpsf_app/widgets/app_bottom_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final language in AppLanguage.values) {
    testWidgets(
      'Ministry opens matrix without tab buttons after bottom navigation: $language',
      (tester) async {
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
                      if (request.url.path.endsWith('/issue-matrix/summary')) {
                        return http.Response(
                          File(
                            'test/fixtures/wg_issue_summary.json',
                          ).readAsStringSync(),
                          200,
                        );
                      }
                      if (request.url.path.endsWith('/issue-matrix')) {
                        return http.Response(
                          '{"success":true,"data":{"items":[],"meta":{"totalPages":0}}}',
                          200,
                        );
                      }
                      return http.Response('{"success":false}', 503);
                    }),
                  ),
                ),
              )
              ..setModuleType(AppModuleType.lineMinistry)
              ..setLanguage(language);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: const MaterialApp(home: DashboardScreen()),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        paths.clear();
        final l10n = AppLocalizations(language);
        await tester.tap(
          find.descendant(
            of: find.byType(AppBottomNavBar),
            matching: find.text(l10n.text('issues')),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.text('wgIssues')), findsNothing);
        expect(find.text(l10n.text('issuesMatrix')), findsOneWidget);
        expect(find.text('12'), findsOneWidget);
        expect(paths.toSet(), {
          '/api/v1/working-group-issues/issue-matrix',
          '/api/v1/working-group-issues/issue-matrix/summary',
        });
        expect(paths, hasLength(2));
        expect(find.text(l10n.text('wgIssues')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
