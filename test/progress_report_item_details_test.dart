import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_section/reports/rgc_decision_details.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_report.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_reports_repository.dart';
import 'package:gpsf_app/screens/report/report_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

http.Response ok(Map<String, dynamic> data) => http.Response.bytes(
  utf8.encode(jsonEncode({'success': true, 'data': data})),
  200,
);

Widget app(AppSettingsController settings, {String? requestDocument}) =>
    AppSettings(
      controller: settings,
      child: MaterialApp(
        home: ReportDetailScreen(
          title: 'Real report',
          report: ProgressReport({
            'id': 46,
            'title': 'Real report',
            'year': 2027,
            'semester': 'S2',
            'ministry': {'name': 'MAFF'},
            if (requestDocument != null)
              'cdcInformation': {
                'requestDocument': {'path': requestDocument},
              },
            'openIssues': [
              {
                'id': 5,
                'title': 'Selected report issue',
                'status': 'NOT_ADDRESSED',
                'category': 'General',
              },
            ],
            'rgcDecisions': [
              {
                'id': 7,
                'decision': 'Selected report decision',
                'status': 'NOT_ADDRESSED',
                'category': 'Climate',
                'indicators': 'Report-specific indicator',
              },
            ],
          }),
        ),
      ),
    );

Finder inSheet(Finder finder) => find.descendant(
  of: find.byType(DraggableScrollableSheet),
  matching: finder,
);

void mobile(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'issue card opens API detail sheet with submitter, document and working Read more',
    (tester) async {
      mobile(tester);
      final calls = <String>[];
      final description = List.filled(
        20,
        'Actual issue description with details.',
      ).join(' ');
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              calls.add(request.url.path);
              expect(request.url.path, '/api/v1/working-group-issues/5');
              return ok({
                'id': 5,
                'title': 'Selected report issue',
                'description': '<p>$description</p>',
                'recommendation': '<p>Actual issue recommendation</p>',
                'issueStatus': {'name': 'Solved'},
                'stakeholder': {'name': 'Agriculture & Agro-Industry'},
                'user': {'name': 'Actual author'},
                'createdAt': '2026-09-03T08:00:00Z',
                'meetingRequest': {
                  'meetingRequestLetter': {
                    'path': '/uploads/selected_request.pdf',
                    'name': 'Selected request.pdf',
                  },
                },
              });
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(app(settings));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('All Issues'), 150);
      await tester.tap(find.text('All Issues'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('report-issue-5')),
        150,
      );
      await tester.tap(find.byKey(const ValueKey('report-issue-5')));
      await tester.pumpAndSettle();
      expect(inSheet(find.text('Issues Details')), findsOneWidget);
      expect(inSheet(find.text('Agriculture & Agro-Industry')), findsOneWidget);
      expect(inSheet(find.text('Not Addressed')), findsOneWidget);
      expect(inSheet(find.text('Submitted By: Actual author')), findsOneWidget);
      final formatted = MaterialLocalizations.of(
        tester.element(find.byType(ReportDetailScreen)),
      ).formatMediumDate(DateTime(2026, 9, 3));
      expect(inSheet(find.text('Submitted Date: $formatted')), findsOneWidget);
      final pdf = tester.widget<PdfAttachmentPreview>(
        inSheet(find.byType(PdfAttachmentPreview)),
      );
      expect(pdf.path, '/uploads/selected_request.pdf');
      await tester.scrollUntilVisible(
        inSheet(find.text('Read more')),
        120,
        scrollable: inSheet(find.byType(Scrollable)),
      );
      expect(tester.widget<Text>(inSheet(find.text(description))).maxLines, 5);
      await tester.tap(inSheet(find.text('Read more')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(inSheet(find.text(description))).maxLines,
        isNull,
      );
      expect(inSheet(find.text('Show less')), findsOneWidget);
      await tester.scrollUntilVisible(
        inSheet(find.text('Show less')).hitTestable(),
        120,
        scrollable: inSheet(find.byType(Scrollable)),
      );
      await tester.tap(inSheet(find.text('Show less')));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(inSheet(find.text(description))).maxLines, 5);
      await tester.scrollUntilVisible(
        inSheet(find.text('Actual issue recommendation')),
        120,
        scrollable: inSheet(find.byType(Scrollable)),
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.byKey(const ValueKey('report-issue-5')), findsOneWidget);
      expect(calls, ['/api/v1/working-group-issues/5']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'RGC card uses CDC linked issue metadata and preserves selected report progress',
    (tester) async {
      mobile(tester);
      final calls = <String>[];
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              calls.add(request.url.path);
              expect(request.url.path, '/api/v1/rgc-decisions/7');
              return ok({
                'id': 7,
                'decision': '<p>Selected report decision</p>',
                'status': 'SOLVED',
                'stakeholder': {'name': 'MAFF'},
                'createdBy': {'name': 'Actual decision author'},
                'createdAt': '2026-09-03T00:00:00Z',
                'submittedToCdcAt': '2026-09-14',
                'indicators': 'Other report indicator',
                'progressUpdate': {
                  'progressSolution': '<p>Actual solution</p>',
                },
                'issues': [
                  {
                    'id': 5,
                    'title': 'Actual linked issue',
                    'description': 'Actual linked description',
                    'recommendation': 'Actual linked recommendation',
                    'stakeholder': {'name': 'Agriculture & Agro-Industry'},
                    'user': {'name': 'PSWG Secretariat A'},
                    'createdAt': '2026-09-02T17:24:20.656Z',
                    'issueStatus': {
                      'code': 'IN_PROGRESS',
                      'name': 'In Progress',
                    },
                    'category': {'name': 'Market Access'},
                    'governmentAgencies': [
                      {
                        'agencyOrder': 1,
                        'stakeholder': {'name': 'Actual agency'},
                      },
                    ],
                    'attachment': '/uploads/linked_request.pdf',
                  },
                  {
                    'id': 6,
                    'title': 'Second linked issue',
                    'stakeholder': {'name': 'Second working group'},
                    'user': {'name': 'Second submitter'},
                    'createdAt': '2026-09-04T00:00:00Z',
                    'recommendation': 'Second issue recommendation',
                    'attachment': {'path': '/uploads/linked_request.pdf'},
                  },
                ],
              });
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        app(settings, requestDocument: '/uploads/report_request.pdf'),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('RGC Decision'), 150);
      await tester.tap(find.text('RGC Decision'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('report-rgcDecision-7')),
        150,
      );
      await tester.tap(find.byKey(const ValueKey('report-rgcDecision-7')));
      await tester.pumpAndSettle();
      expect(inSheet(find.text('RGC Decision Details')), findsOneWidget);
      expect(inSheet(find.byType(CdcRgcDecisionIssueDetails)), findsOneWidget);
      expect(
        inSheet(find.text('Government Agency : Actual agency')),
        findsOneWidget,
      );
      expect(inSheet(find.text('In Progress')), findsOneWidget);
      expect(inSheet(find.text('Agriculture & Agro-Industry')), findsOneWidget);
      expect(inSheet(find.text('Market Access')), findsOneWidget);
      expect(
        inSheet(find.text('Submitted By : PSWG Secretariat A')),
        findsOneWidget,
      );
      expect(
        inSheet(find.text('Submitted Date : Sep 3, 2026')),
        findsOneWidget,
      );
      expect(inSheet(find.byType(PdfAttachmentPreview)), findsOneWidget);
      expect(
        tester
            .widget<PdfAttachmentPreview>(
              inSheet(find.byType(PdfAttachmentPreview)),
            )
            .path,
        '/uploads/linked_request.pdf',
      );
      expect(inSheet(find.text('Actual decision author')), findsNothing);
      expect(inSheet(find.text('Submitted Date : Sep 14, 2026')), findsNothing);
      expect(inSheet(find.text('report_request.pdf')), findsNothing);
      expect(
        inSheet(find.text('Actual linked recommendation')),
        findsOneWidget,
      );
      expect(inSheet(find.text('Actual linked description')), findsOneWidget);
      expect(
        inSheet(find.text('Actual linked issue\nActual linked recommendation')),
        findsNothing,
      );
      await tester.scrollUntilVisible(
        inSheet(find.text('Report-specific indicator')),
        120,
        scrollable: inSheet(find.byType(Scrollable)).first,
      );
      expect(inSheet(find.text('Other report indicator')), findsNothing);
      await tester.scrollUntilVisible(
        inSheet(find.text('Progress Solution')),
        120,
        scrollable: inSheet(find.byType(Scrollable)).first,
      );
      expect(inSheet(find.text('Progress Solution')), findsOneWidget);
      await tester.scrollUntilVisible(
        inSheet(find.text('Source of Verification')),
        120,
        scrollable: inSheet(find.byType(Scrollable)).first,
      );
      expect(inSheet(find.text('Source of Verification')), findsOneWidget);
      await tester.scrollUntilVisible(
        inSheet(find.text('Second issue recommendation')),
        160,
        scrollable: inSheet(find.byType(Scrollable)).first,
      );
      expect(inSheet(find.text('Second working group')), findsOneWidget);
      expect(
        inSheet(find.text('Submitted By : Second submitter')),
        findsOneWidget,
      );
      expect(calls, ['/api/v1/rgc-decisions/7']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'issue detail retries failed request and closes without leaving report',
    (tester) async {
      mobile(tester);
      var calls = 0;
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              expect(request.url.path, '/api/v1/working-group-issues/5');
              if (++calls == 1) {
                return http.Response(
                  jsonEncode({'success': false, 'message': 'Unavailable'}),
                  503,
                );
              }
              return ok({
                'id': 5,
                'recommendation': 'Recovered recommendation',
              });
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(app(settings));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('All Issues'), 150);
      await tester.tap(find.text('All Issues'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('report-issue-5')),
        150,
      );
      await tester.tap(find.byKey(const ValueKey('report-issue-5')));
      await tester.pumpAndSettle();
      expect(
        inSheet(
          find.text('The server is unavailable (503). Please try again later.'),
        ),
        findsOneWidget,
      );
      await tester.tap(inSheet(find.text('Retry')));
      await tester.pumpAndSettle();
      expect(inSheet(find.text('Recovered recommendation')), findsOneWidget);
      expect(calls, 2);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.byType(ReportDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('item detail rejects an API record with a different ID', () async {
    final api = ApiClient(
      client: MockClient(
        (request) async => ok({'id': 99, 'title': 'Different issue'}),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      ProgressReportsRepository(
        api,
      ).getItemDetail({'id': 5}, type: ProgressReportItemType.issue),
      throwsA(isA<ApiException>()),
    );
  });

  for (final document in ['/uploads/report_request.pdf', null]) {
    testWidgets(
      'RGC sheet uses actual report document when linked record has none: $document',
      (tester) async {
        mobile(tester);
        final settings = AppSettingsController(
          authRepository: AuthRepository(
            ApiClient(
              client: MockClient((request) async {
                expect(request.url.path, '/api/v1/rgc-decisions/7');
                return ok({
                  'id': 7,
                  'createdBy': {'name': ''},
                  'issues': [],
                });
              }),
            ),
          ),
        )..setLanguage(AppLanguage.english);
        addTearDown(settings.dispose);
        await tester.pumpWidget(app(settings, requestDocument: document));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('RGC Decision'), 150);
        await tester.tap(find.text('RGC Decision'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('report-rgcDecision-7')),
          150,
        );
        await tester.tap(find.byKey(const ValueKey('report-rgcDecision-7')));
        await tester.pumpAndSettle();
        expect(inSheet(find.text('Submitted By : —')), findsOneWidget);
        if (document == null) {
          expect(inSheet(find.byType(PdfAttachmentPreview)), findsNothing);
        } else {
          expect(
            tester
                .widget<PdfAttachmentPreview>(
                  inSheet(find.byType(PdfAttachmentPreview)),
                )
                .path,
            document,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'report item null progress fields stay empty and partial linked issues retain their detail',
    () async {
      final api = ApiClient(
        client: MockClient(
          (request) async => ok({
            'id': 7,
            'indicators': 'Other report indicator',
            'progressUpdate': {'progressSolution': 'Other report solution'},
            'issues': [
              {
                'id': 5,
                'title': 'Linked issue',
                'recommendation': 'Actual linked recommendation',
              },
            ],
          }),
        ),
      );
      addTearDown(api.close);
      final detail = await ProgressReportsRepository(api).getItemDetail({
        'id': 7,
        'indicators': null,
        'progressUpdate': null,
        'issues': [
          {'id': 5, 'title': 'Linked issue'},
        ],
      }, type: ProgressReportItemType.rgcDecision);
      expect(detail['indicators'], isNull);
      expect(detail['progressUpdate'], isNull);
      expect(
        (detail['issues'] as List).single['recommendation'],
        'Actual linked recommendation',
      );
    },
  );
}
