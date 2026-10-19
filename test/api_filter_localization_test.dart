import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/network/filter_catalog_repository.dart';
import 'package:gpsf_app/core/widgets/filters/api_filter_sheet.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('dashboard options follow language without changing selections', (
    tester,
  ) async {
    final settings = AppSettingsController()..setLanguage(AppLanguage.khmer);
    addTearDown(settings.dispose);
    final api = ApiClient(
      client: MockClient((request) async {
        final Object data = request.url.path.endsWith('/saved')
            ? []
            : {
                'byWorkingGroup': [
                  {
                    'workingGroupName': 'Agriculture',
                    'workingGroupKhName': 'កសិកម្ម',
                  },
                ],
                'byPrimaryAgency': [
                  {'agencyName': 'MAFF'},
                ],
                'byCategory': [
                  {'categoryName': 'Taxation', 'categoryKhName': 'ពន្ធដារ'},
                  {'categoryName': 'Fallback', 'categoryKhName': '  '},
                ],
              };
        return http.Response(
          jsonEncode({'success': true, 'data': data}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);
    final sections = await FilterCatalogRepository(api).dashboard('plenary');
    expect(sections.first.options.single.value, 'Agriculture');
    expect(sections[3].options.first.value, 'Taxation');
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: ApiFilterSheet(
            initial: FilterSelection(),
            load: () async => sections,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('កសិកម្ម'), findsOneWidget);
    expect(find.text('ពន្ធដារ'), findsOneWidget);
    expect(find.text('Fallback'), findsOneWidget);
    expect(find.text('MAFF'), findsOneWidget);
    expect(find.text('បានដោះស្រាយ'), findsOneWidget);
    expect(find.text('កំពុងដំណើរការ'), findsOneWidget);
    expect(find.text('មិនទាន់ដោះស្រាយ'), findsOneWidget);
    expect(find.text('Solved'), findsNothing);

    final solved = find.byKey(const ValueKey('filter-local.status-SOLVED'));
    await tester.tap(solved);
    await tester.pump();
    settings.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();
    expect(find.text('Agriculture'), findsOneWidget);
    expect(find.text('Taxation'), findsOneWidget);
    expect(find.text('Solved'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Not Addressed'), findsOneWidget);
    expect(
      find.descendant(of: solved, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
