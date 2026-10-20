import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/auth/data/auth_user.dart';
import 'package:gpsf_app/features/shared/issues/widgets/issue_agency_logo.dart';
import 'package:gpsf_app/screens/report/report_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final module in [
    AppModuleType.cdcSecretariat,
    AppModuleType.lineMinistry,
  ]) {
    testWidgets('$module decision cards display each ministry API logo', (
      tester,
    ) async {
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    if (request.url.path.endsWith('/plenaries/6')) {
                      return http.Response(
                        jsonEncode({
                          'success': true,
                          'data': {
                            'id': 6,
                            'statusCode': 'SENT',
                            'meetingDate': '2026-10-19',
                          },
                        }),
                        200,
                      );
                    }
                    if (request.url.path.endsWith('/rgc-decisions')) {
                      expect(
                        request.url.queryParameters['ministryOnly'],
                        'true',
                      );
                      expect(request.headers['x-user-id'], '77');
                    } else if (request.url.path.endsWith(
                      '/rgc-decisions/cdc-gpsf',
                    )) {
                      expect(
                        request.url.queryParameters.containsKey('ministryOnly'),
                        isFalse,
                      );
                      expect(request.headers.containsKey('x-user-id'), isFalse);
                    }
                    return http.Response(
                      jsonEncode({
                        'success': true,
                        'data': request.url.path.endsWith('/progress-reports')
                            ? []
                            : {
                                'items': [
                                  for (var i = 0; i < 3; i++)
                                    {
                                      'id': i + 1,
                                      'plenaryId': 6,
                                      'plenary': {'id': 6, 'name': '22nd'},
                                      'stakeholder': {
                                        'id': i + 1,
                                        'name': ['MoT', 'MAFF', 'MEF'][i],
                                        'logo': [
                                          '/uploads/stakeholders/MoT.png',
                                          'https://example.com/MAFF.jpg',
                                          null,
                                        ][i],
                                      },
                                    },
                                ],
                                'meta': {'totalPages': 1},
                              },
                      }),
                      200,
                    );
                  }),
                ),
              ),
            )
            ..setModuleType(module)
            ..setLanguage(AppLanguage.english);
      settings.currentUser = const AuthUser(
        id: 77,
        email: 'test@example.com',
        name: 'Test ministry',
        isActive: true,
      );
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: Scaffold(body: ReportScreen())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('RGC Decision'));
      await tester.tap(find.text('RGC Decision'));
      await tester.pumpAndSettle();
      final logos = tester.widgetList<IssueAgencyLogo>(
        find.byType(IssueAgencyLogo),
      );
      expect(logos.map((logo) => logo.path), [
        '/uploads/stakeholders/MoT.png',
        'https://example.com/MAFF.jpg',
        '',
      ]);
      final imageUrls = tester
          .widgetList<Image>(find.byType(Image))
          .map((widget) => widget.image)
          .whereType<NetworkImage>()
          .map((image) => image.url);
      expect(
        imageUrls,
        containsAll([
          'https://admin-mis-stage.datacolabx.com/uploads/stakeholders/MoT.png',
          'https://example.com/MAFF.jpg',
        ]),
      );
      expect(find.text('MoT'), findsOneWidget);
      expect(find.text('MAFF'), findsOneWidget);
      expect(find.text('MEF'), findsOneWidget);
      expect(find.text('Sent'), findsNWidgets(3));
      expect(find.text('Oct 19, 2026'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  }
}
