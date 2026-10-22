import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/private_sector/issues/issues_screen.dart';
import 'package:gpsf_app/features/shared/issues/data/working_group_issue.dart';
import 'package:gpsf_app/features/shared/issues/widgets/issue_agency_logo.dart';

void main() {
  testWidgets('private sector issue card uses the primary ministry API logo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final issue = jsonDecode(
      File('test/fixtures/private_sector_issue_detail.json').readAsStringSync(),
    )['data'];
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path.contains('/summary/')) {
          return http.Response(
            File('test/fixtures/wg_issue_summary.json').readAsStringSync(),
            200,
          );
        }
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'success': true,
              'data': {
                'items': [issue],
                'meta': {'totalPages': 1},
              },
            }),
          ),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final settings = AppSettingsController(authRepository: AuthRepository(api));
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: Scaffold(body: IssuesScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(issue['title'] as String));
    await tester.pumpAndSettle();
    final logo = find.byType(IssueAgencyLogo);
    expect(logo, findsOneWidget);
    expect(
      tester.widget<IssueAgencyLogo>(logo).path,
      '/uploads/stakeholders/1788369688560-MAFF.jpg',
    );
    // The image may have failed in the test environment, but the widget must
    // remain wired to the API logo rather than a fixed account_balance icon.
    expect(tester.widget<IssueAgencyLogo>(logo).size, 32);
    expect(tester.takeException(), isNull);
  });

  test(
    'logo follows primary agency order rather than submitting stakeholder',
    () {
      final issue = WorkingGroupIssue.fromJson({
        'id': 12,
        'title': 'Issue',
        'stakeholder': {'name': 'Private Sector', 'logo': '/wrong-logo.jpg'},
        'governmentAgencies': [
          {
            'agencyOrder': 2,
            'stakeholder': {'name': 'MEF', 'logo': '/mef.jpg'},
          },
          {
            'agencyOrder': 1,
            'stakeholder': {
              'name': 'MAFF',
              'logo': '/uploads/stakeholders/1788369688560-MAFF.jpg',
            },
          },
        ],
      });
      expect(issue.agency, 'MAFF');
      expect(issue.agencyLogo, '/uploads/stakeholders/1788369688560-MAFF.jpg');
    },
  );

  testWidgets(
    'relative ministry logo uses the API host and handles image failure',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IssueAgencyLogo(
            path: '/uploads/stakeholders/1788369688560-MAFF.jpg',
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://admin-mis-stage.datacolabx.com/uploads/stakeholders/1788369688560-MAFF.jpg',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing logo retains the fallback icon', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IssueAgencyLogo(path: '')));
    expect(find.byIcon(Icons.account_balance), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
