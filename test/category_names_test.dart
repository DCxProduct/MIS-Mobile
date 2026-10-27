import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/text/api_localized_names.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';

const categories = [
  {'id': 1, 'name': 'General', 'khName': 'បញ្ហាទូទៅ'},
  {'id': 7, 'name': 'Market Access', 'khName': 'ការចូលទៅកាន់ទីផ្សារ'},
  {'id': 18, 'name': 'Regulation', 'khName': 'បទប្បញ្ញត្តិ'},
  {'id': 21, 'name': 'New category', 'khName': null},
];

void main() {
  test('Uses API Khmer names, handles joined categories and missing names', () {
    final names = ApiLocalizedNames(categories);
    expect(
      names.display('General, Regulation', AppLanguage.khmer),
      'បញ្ហាទូទៅ, បទប្បញ្ញត្តិ',
    );
    expect(names.display('General', AppLanguage.english), 'General');
    for (final value in ['New category', 'Unknown category', '']) {
      expect(names.display(value, AppLanguage.khmer), value);
    }
  });

  testWidgets('API category names switch language across every module', (
    tester,
  ) async {
    var requests = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((request) async {
            expect(request.url.path, '/api/v1/working-group-issues/categories');
            requests++;
            return http.Response(
              jsonEncode({'success': true, 'data': categories}),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      ),
    );
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  Text(AppLocalizations.of(context).category('Market Access')),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Market Access'), findsOneWidget);
    await settings.loadCategoryNames();
    for (final module in AppModuleType.values) {
      settings.setModuleType(module);
      await tester.pump();
      expect(find.text('ការចូលទៅកាន់ទីផ្សារ'), findsOneWidget);
      settings.setLanguage(AppLanguage.english);
      await tester.pump();
      expect(find.text('Market Access'), findsOneWidget);
      settings.setLanguage(AppLanguage.khmer);
    }
    await settings.loadCategoryNames();
    expect(requests, 1);
    settings.clearSession();
    await tester.pump();
    expect(find.text('Market Access'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Failed lookup keeps original values and retries', () async {
    var requests = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((_) async {
            requests++;
            return requests == 1
                ? http.Response('{}', 500)
                : http.Response(
                    jsonEncode({'success': true, 'data': categories}),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8',
                    },
                  );
          }),
        ),
      ),
    );
    addTearDown(settings.dispose);
    await settings.loadCategoryNames();
    expect(
      settings.categoryNames.display('General', AppLanguage.khmer),
      'General',
    );
    await settings.loadCategoryNames();
    expect(
      settings.categoryNames.display('General', AppLanguage.khmer),
      'បញ្ហាទូទៅ',
    );
  });
}
