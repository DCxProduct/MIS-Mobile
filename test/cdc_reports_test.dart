import 'dart:convert';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_section/reports/rgc_decision_details.dart';
import 'package:gpsf_app/screens/report/report_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  http.Response ok(Object data) =>
      http.Response(jsonEncode({'success': true, 'data': data}), 200);

  testWidgets('CDC decisions use ministry, pages, and selected detail ID', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requested = <Uri>[];
    final client = MockClient((request) async {
      requested.add(request.url);
      final path = request.url.path;
      if (path.endsWith('/lookups/ministries')) {
        return ok({
          'items': [
            {'id': 12, 'name': 'MPWT'},
            {'id': 13, 'name': 'MAFF'},
          ],
        });
      }
      if (path.endsWith('/meeting-requests')) {
        return ok([
          {
            'id': 2,
            'title': 'Meeting request',
            'meetingRequestLetter': {
              'name': 'Request Doc',
              'path': '/uploads/meeting-documents/request.pdf',
            },
          },
        ]);
      }
      if (path.endsWith('/plenaries/3')) {
        return ok({'id': 3, 'deadline': '2026-09-29T17:00:00.000Z'});
      }
      if (path.endsWith('/rgc-decisions/179')) {
        return ok({
          'id': 179,
          'stakeholder': {'name': 'MPWT'},
          'status': 'In Progress',
          'meetingDate': '2023-11-13',
          'plenaryId': 3,
          'category': 'Legislation',
          'focalPerson': 'Peng Ponea',
          'decision': '<p>A real decision from the API</p>',
          'verificationSource': '<p>Source from the API</p>',
          'issues': [
            {
              'issueStatus': {'name': 'Solved'},
              'description': 'A real issue from the API',
              'user': {'name': 'PSWG Secretariat A'},
              'createdAt': '2026-09-03T02:35:59.659Z',
              'attachment': '/uploads/issues/1788402959624-Issue_reference.pdf',
              'governmentAgencies': [
                {
                  'agencyOrder': 2,
                  'stakeholder': {'name': 'MEF'},
                },
                {
                  'agencyOrder': 1,
                  'stakeholder': {'name': 'MAFF'},
                },
              ],
              'meetingRequest': {
                'id': 2,
                'meetings': [
                  {'meetingDate': '2026-09-03'},
                ],
              },
            },
          ],
        });
      }
      if (path.endsWith('/rgc-decisions')) {
        final ministry = request.url.queryParameters['stakeholderId'];
        final page = request.url.queryParameters['page'];
        expect(request.url.queryParameters['limit'], '20');
        if (ministry == '13') {
          return ok({
            'items': [
              {
                'id': 180,
                'stakeholder': {'name': 'MAFF'},
                'status': 'Solved',
                'category': 'Agriculture',
              },
            ],
            'meta': {'totalPages': 1},
          });
        }
        return ok({
          'items': [
            {
              'id': page == '1' ? 179 : 181,
              'stakeholder': {'name': 'MPWT'},
              'status': 'In Progress',
              'meetingDate': '2023-11-13',
              'category': 'Legislation',
              'focalPerson': 'Peng Ponea',
            },
          ],
          'meta': {'totalPages': 2},
        });
      }
      return http.Response('Not found', 404);
    });
    final api = ApiClient(client: client);
    addTearDown(api.close);
    final settings = AppSettingsController(authRepository: AuthRepository(api))
      ..setModuleType(AppModuleType.cdcSection)
      ..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: Scaffold(body: ReportScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MPWT'), findsWidgets);
    expect(
      requested.any(
        (uri) =>
            uri.queryParameters['stakeholderId'] == '12' &&
            uri.queryParameters['page'] == '1',
      ),
      isTrue,
    );

    await tester.ensureVisible(find.text('Load more'));
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.text('View Details'), findsNWidgets(2));
    expect(
      requested.any(
        (uri) =>
            uri.queryParameters['stakeholderId'] == '12' &&
            uri.queryParameters['page'] == '2',
      ),
      isTrue,
    );

    await tester.tap(find.text('View Details').first);
    await tester.pumpAndSettle();
    expect(find.byType(CdcRgcDecisionOverviewScreen), findsOneWidget);
    expect(find.text('179'), findsOneWidget);
    expect(find.text('Sep 30, 2026'), findsOneWidget);
    expect(requested.any((uri) => uri.path.endsWith('/plenaries/3')), isTrue);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    expect(find.byIcon(Icons.file_copy_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(
      requested.any((uri) => uri.path.endsWith('/rgc-decisions/179')),
      isTrue,
    );
    await tester.tap(find.text('A real decision from the API'));
    await tester.pumpAndSettle();
    expect(find.byType(CdcRgcDecisionIssueScreen), findsOneWidget);
    expect(find.text('A real issue from the API'), findsOneWidget);
    expect(find.text('Meeting Request Document'), findsOneWidget);
    expect(find.text('Issue_reference.pdf'), findsOneWidget);
    final preview = tester.widget<PdfAttachmentPreview>(
      find.byType(PdfAttachmentPreview),
    );
    expect(preview.path, '/uploads/issues/1788402959624-Issue_reference.pdf');
    final submitter = find.textContaining(
      'PSWG Secretariat A',
      findRichText: true,
    );
    final submittedDate = find.textContaining(
      'Sep 3, 2026',
      findRichText: true,
    );
    expect(submitter, findsOneWidget);
    expect(submittedDate, findsOneWidget);
    expect(
      tester.getRect(submitter).left,
      lessThan(tester.getRect(submittedDate).left),
    );
    expect(
      tester.getRect(submittedDate).left,
      lessThan(
        tester.getRect(find.textContaining('MAFF', findRichText: true)).left,
      ),
    );
    expect(find.textContaining('MAFF', findRichText: true), findsOneWidget);
    final agencyRow = find.ancestor(
      of: find.textContaining('MAFF', findRichText: true),
      matching: find.byType(SingleChildScrollView),
    );
    await tester.drag(agencyRow, const Offset(-800, 0));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Gov’t Fifth Agency', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    expect(
      requested.any((uri) => uri.path.endsWith('/meeting-requests')),
      isFalse,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filter-primaryAgency-MAFF')));
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    expect(
      requested.any(
        (uri) =>
            uri.queryParameters['stakeholderId'] == '13' &&
            uri.queryParameters['page'] == '1',
      ),
      isTrue,
    );
  });
}
