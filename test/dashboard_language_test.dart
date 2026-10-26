import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/filters/filter_models.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/dashboard/data/dashboard_repository.dart';
import 'package:gpsf_app/features/shared/dashboard/data/dashboard_snapshot.dart';
import 'package:gpsf_app/features/shared/dashboard/data/pswg_dashboard.dart';
import 'package:gpsf_app/features/shared/dashboard/data/working_group_summary.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/pswg_live_dashboard.dart';
import 'package:gpsf_app/features/private_sector/dashboard/tabs/working_group_tab.dart';
import 'package:gpsf_app/features/private_sector/dashboard/tabs/categories_tab.dart';
import 'package:gpsf_app/features/cdc_secretariat/dashboard/working_group_tab.dart';
import 'package:gpsf_app/features/cdc_secretariat/dashboard/categories_tab.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final fixture = File(
    'test/fixtures/localized_plenary_dashboard.json',
  ).readAsStringSync().replaceFirst('\uFEFF', '');
  final json =
      (jsonDecode(fixture) as Map<String, dynamic>)['data']
          as Map<String, dynamic>;

  test('dashboard parsers preserve every Khmer name supplied by the API', () {
    final live = PswgDashboard.fromJson(json);
    final snapshot = DashboardSnapshot.fromJson(
      json,
      scope: DashboardScope.plenary,
    );
    for (final groups in [live.workingGroups, snapshot.workingGroups]) {
      expect(groups.length, (json['byWorkingGroup'] as List).length);
      for (var i = 0; i < groups.length; i++) {
        expect(
          groups[i].displayName(AppLanguage.khmer),
          json['byWorkingGroup'][i]['workingGroupKhName'],
        );
        expect(
          groups[i].displayName(AppLanguage.english),
          json['byWorkingGroup'][i]['workingGroupName'],
        );
      }
    }
    expect(live.categories.first.displayName(AppLanguage.khmer), 'អាកាសធាតុ');
    expect(
      snapshot.categories.first.displayName(AppLanguage.khmer),
      'អាកាសធាតុ',
    );
    final row = Map<String, dynamic>.from(json['byWorkingGroup'][0] as Map);
    for (final absent in [null, '', '  ']) {
      row['workingGroupKhName'] = absent;
      expect(
        WorkingGroupSummary.fromJson(row).displayName(AppLanguage.khmer),
        row['workingGroupName'],
      );
    }
  });

  for (final role in AppModuleType.values) {
    for (final scope in DashboardScope.values) {
      testWidgets('$role $scope names switch without losing filtered data', (
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
                      expect(
                        request.url.path,
                        '/api/v1/dashboards/${scope.name}/live',
                      );
                      return http.Response(
                        fixture,
                        200,
                        headers: {
                          'content-type': 'application/json; charset=utf-8',
                        },
                      );
                    }),
                  ),
                ),
              )
              ..setModuleType(role)
              ..setLanguage(AppLanguage.english);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: PswgDataLoader(
                    scope: scope,
                    selection: FilterSelection({
                      'local.workingGroup': {'Agriculture & Agro-Industry'},
                      'local.status': {'IN_PROGRESS'},
                    }),
                    builder: (_) => Column(
                      children: role == AppModuleType.cdcSecretariat
                          ? const [
                              CdcSecretariatWorkingGroupTab(),
                              CdcSecretariatCategoriesTab(),
                            ]
                          : const [WorkingGroupTab(), CategoriesTab()],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final khmerName =
            json['byWorkingGroup'][0]['workingGroupKhName'] as String;
        for (final language in [
          AppLanguage.khmer,
          AppLanguage.english,
          AppLanguage.khmer,
        ]) {
          settings.setLanguage(language);
          await tester.pumpAndSettle();
          final khmer = language == AppLanguage.khmer;
          expect(
            find.text(khmer ? khmerName : 'Agriculture & Agro-Industry'),
            findsOneWidget,
          );
          expect(
            find.text(khmer ? 'Agriculture & Agro-Industry' : khmerName),
            findsNothing,
          );
          expect(find.text(khmer ? 'អាកាសធាតុ' : 'Climate'), findsOneWidget);
          expect(find.text('Tourism'), findsNothing);
          expect(
            PswgDataScope.maybeOf(
              tester.element(find.byType(Column).first),
            )?.workingGroups.single.inProgress,
            1,
          );
          expect(calls, 1);
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
