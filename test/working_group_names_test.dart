import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/text/working_group_names.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';

const groups = [
  {
    'id': 14,
    'name': 'Agriculture & Agro-Industry',
    'khName': 'ក្រុមការងារ ក៖ ផ្នែកកសិកម្ម កសិ-ឧស្សាហកម្ម',
  },
  {'id': 15, 'name': 'Tourism', 'khName': 'ក្រុមការងារ ខ៖ ផ្នែកទេសចរណ៍'},
  {'id': 17, 'name': 'Law, Tax, and Governance', 'khName': 'ក្រុមការងារ ឃ'},
  {'id': 18, 'name': 'No translation', 'khName': null},
];

void main() {
  test('Preserves unknown names and supports names containing commas', () {
    final names = WorkingGroupNames(groups);
    expect(
      names.display('Law, Tax, and Governance, Tourism', AppLanguage.khmer),
      'ក្រុមការងារ ឃ, ក្រុមការងារ ខ៖ ផ្នែកទេសចរណ៍',
    );
    for (final value in ['MAFF', 'PSWG Secretariat A', 'No translation', '']) {
      expect(names.display(value, AppLanguage.khmer), value);
    }
    expect(names.display('Tourism', AppLanguage.english), 'Tourism');
  });

  testWidgets(
    'API names load once, rebuild and switch language across modules',
    (tester) async {
      var requests = 0;
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              expect(request.url.path, '/api/v1/stakeholders/working-groups');
              requests++;
              return http.Response(
                jsonEncode({'success': true, 'data': groups}),
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
                    Text(AppLocalizations.of(context).workingGroup('Tourism')),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Tourism'), findsOneWidget);
      await settings.loadWorkingGroupNames();
      await tester.pump();
      expect(find.text('ក្រុមការងារ ខ៖ ផ្នែកទេសចរណ៍'), findsOneWidget);
      for (final module in AppModuleType.values) {
        settings.setModuleType(module);
        await tester.pump();
        expect(find.text('ក្រុមការងារ ខ៖ ផ្នែកទេសចរណ៍'), findsOneWidget);
      }
      settings.setLanguage(AppLanguage.english);
      await tester.pump();
      expect(find.text('Tourism'), findsOneWidget);
      settings.setLanguage(AppLanguage.khmer);
      await settings.loadWorkingGroupNames();
      await tester.pump();
      expect(find.text('ក្រុមការងារ ខ៖ ផ្នែកទេសចរណ៍'), findsOneWidget);
      expect(requests, 1);
      settings.clearSession();
      await tester.pump();
      expect(find.text('Tourism'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('Optional lookup failure keeps English and can retry', () async {
    var attempts = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((_) async {
            attempts++;
            return attempts == 1
                ? http.Response('{}', 500)
                : http.Response(
                    jsonEncode({'success': true, 'data': groups}),
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
    await settings.loadWorkingGroupNames();
    expect(
      settings.workingGroupNames.display('Tourism', AppLanguage.khmer),
      'Tourism',
    );
    await settings.loadWorkingGroupNames();
    expect(
      settings.workingGroupNames.display('Tourism', AppLanguage.khmer),
      'ក្រុមការងារ ខ៖ ផ្នែកទេសចរណ៍',
    );
  });
}
