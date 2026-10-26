import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/features/cdc_secretariat/meetings/summary_issue_details.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/private_sector/reports/meeting_summary_detail_screen.dart';
import 'package:gpsf_app/features/shared/meetings/data/meeting_summary.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('summary 3 preserves both supplied issue records independently', () {
    final data =
        jsonDecode(
              File(
                'test/fixtures/ministry_summary_3.json',
              ).readAsStringSync().replaceFirst('\uFEFF', ''),
            )
            as Map<String, dynamic>;
    final summary = MeetingSummary(data);
    expect(summary.issues, hasLength(2));
    for (var index = 0; index < summary.issues.length; index++) {
      final issue = summary.issues[index];
      final source = data['issues'][index];
      expect(issue.title, source['issue']);
      expect(issue.descriptionHtml, source['issueDescription']);
      expect(issue.rgcDecisionHtml, source['rgcDecision']);
      expect(issue.nextStepHtml, source['nextStep']);
      expect(issue.referencePath, source['referenceDocument']['path']);
      expect(issue.attachmentSize, 1947246);
      expect(issue.referenceSize, 1947246);
      expect(issue.submittedBy, 'MAFF');
    }
    expect(summary.issues.first.category, 'General');
    expect(summary.issues.last.category, 'Regulation');
    expect(summary.issues.first.remarkHtml, isEmpty);
    expect(summary.issues.last.remarkHtml, isNotEmpty);
  });
  testWidgets('ministry summary opens complete selected issue data', (
    tester,
  ) async {
    final settings = AppSettingsController()
      ..setLanguage(AppLanguage.english)
      ..setModuleType(AppModuleType.lineMinistry);
    addTearDown(settings.dispose);
    final summary = MeetingSummary({
      'id': 3,
      'issues': [
        {
          'id': 17,
          'issue': 'Selected ministry issue',
          'category': 'General',
          'status': 'IN_PROGRESS',
          'issueDescription': '<p>Full description</p>',
          'recommendation': '<p>Full recommendation</p>',
          'rgcDecision': '<p>Selected RGC decision</p>',
          'nextStep': '<p>Selected next step</p>',
          'remark': '<p>Selected remark</p>',
          'escalation': 'CDC',
          'agencies': [
            {'order': 1, 'name': 'MAFF', 'logo': '/maff.png'},
          ],
          'referenceDocument': {
            'path': '/solution.pdf',
            'name': 'Solution.pdf',
          },
        },
      ],
    });
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(home: MeetingSummaryDetailScreen(summary: summary)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selected ministry issue'));
    await tester.pumpAndSettle();
    expect(find.byType(CdcSummaryIssueDetails), findsOneWidget);
    expect(find.text('MAFF'), findsOneWidget);
    expect(find.text('Solution.pdf'), findsOneWidget);
    final scroll = find.descendant(
      of: find.byType(CdcSummaryIssueDetails),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Selected next step'),
      200,
      scrollable: scroll.first,
    );
    expect(find.text('Selected RGC decision'), findsOneWidget);
    expect(find.text('Selected next step'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final module in [
    AppModuleType.cdcSecretariat,
    AppModuleType.privateSector,
  ]) {
    testWidgets(
      '$module summary shows separate documents and complete web fields',
      (tester) async {
        final json =
            jsonDecode(
                  File(
                    'test/fixtures/cdcgpsf_meeting_summary.json',
                  ).readAsStringSync().replaceFirst('\uFEFF', ''),
                )
                as Map<String, dynamic>;
        final summary = MeetingSummary(json);
        final issue = summary.issues.single;
        expect(summary.pswg, 'Tourism');
        expect(summary.governmentAgency, 'MoT');
        expect(summary.sentBy, 'MoT');
        expect(summary.summaryDocumentName, 'Meeting_summary_ reference.pdf');
        expect(summary.summaryDocumentSize, 1947246);
        expect(summary.summaryDocumentPath, contains('/meeting-summaries/'));
        expect(
          summary.requestedDate,
          DateTime.parse('2026-10-19T02:45:51.251Z'),
        );
        expect(issue.escalation, 'CDC');
        expect(issue.agencyLogos[2], contains('MEF.png'));
        expect(issue.rgcDecisionHtml, contains('<p>'));
        expect(issue.nextStepHtml, isNotEmpty);
        expect(issue.remarkHtml, isNotEmpty);
        final settings = AppSettingsController()
          ..setLanguage(AppLanguage.english)
          ..setModuleType(module);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: MeetingSummaryDetailScreen(summary: summary),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Meeting Information'), findsOneWidget);
        expect(find.text('meeting_request_latter.pdf'), findsOneWidget);
        expect(find.text('meeting_document_reference.pdf'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Meeting_summary_ reference.pdf'),
          250,
        );
        final summaryAttachment = tester.widget<PdfAttachmentPreview>(
          find.ancestor(
            of: find.text('Meeting_summary_ reference.pdf'),
            matching: find.byType(PdfAttachmentPreview),
          ),
        );
        expect(summaryAttachment.path, summary.summaryDocumentPath);
        expect(find.text('1.9 MB'), findsOneWidget);
        await tester.scrollUntilVisible(find.text(issue.title), 250);
        await tester.tap(find.text(issue.title));
        await tester.pumpAndSettle();
        expect(find.byType(CdcSummaryIssueDetails), findsOneWidget);
        expect(find.text('MEF'), findsOneWidget);
        expect(find.text('CDC'), findsOneWidget);
        expect(find.text('Issue_solution_reference.pdf'), findsOneWidget);
        final sheetScroll = find.descendant(
          of: find.byType(CdcSummaryIssueDetails),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          find.text('Remark'),
          300,
          scrollable: sheetScroll.first,
        );
        expect(find.text('Remark'), findsOneWidget);
        expect(find.text('Next Step'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  // Contract from the backend summary serializer and the web issue dialog.
  final webSummary =
      jsonDecode(
            File(
              'test/fixtures/ministry_meeting_summary.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  test('summary API issue rows inherit the exact context used by web', () {
    final summary = MeetingSummary(webSummary);
    final issue = summary.issues.single;
    expect(issue.submittedBy, 'MoT');
    expect(issue.submittedDate, DateTime.utc(2026, 9, 14));
    expect(issue.governmentAgencies, {1: 'MoT', 3: 'Third agency'});
    expect(issue.governmentAgencies.containsKey(2), isFalse);
  });

  testWidgets(
    'private summary detail endpoint fills the complete Ministry issue dialog',
    (tester) async {
      var calls = 0;
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    calls++;
                    expect(request.url.path, '/api/v1/meeting-summaries/4');
                    return http.Response(
                      jsonEncode({'success': true, 'data': webSummary}),
                      200,
                      headers: {
                        'content-type': 'application/json; charset=utf-8',
                      },
                    );
                  }),
                ),
              ),
            )
            ..setLanguage(AppLanguage.english)
            ..setModuleType(AppModuleType.privateSector);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: MeetingSummaryDetailScreen(id: 4)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('9:00 AM'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Problems on direct flights to Cambodia'),
        250,
      );
      await tester.tap(find.text('Problems on direct flights to Cambodia'));
      await tester.pumpAndSettle();
      expect(find.byType(CdcSummaryIssueDetails), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('MoT'),
        ),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.textContaining('Sep 14', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('PSWG Secretariat', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('Summary editor', findRichText: true),
        findsNothing,
      );
      expect(find.text('Issue_reference.pdf'), findsOneWidget);
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.byType(Wrap)),
        findsOneWidget,
      );
      settings.setLanguage(AppLanguage.khmer);
      await tester.pumpAndSettle();
      expect(
        find.text(
          AppLocalizations(AppLanguage.khmer).text('submittedBy'),
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
  final issueJson = <String, dynamic>{
    'id': 9,
    'issue': 'Actual summary issue',
    'submittedBy': {'name': 'Actual submitter'},
    'submittedDate': '2026-10-19T09:00:00Z',
    'category': {'name': 'Actual category'},
    'issueStatus': {'code': 'IN_PROGRESS', 'name': 'In Progress'},
    'issueDescription': '<p>Actual issue description</p>',
    'recommendation': '<p>Actual recommendation</p>',
    'governmentAgencies': [
      {
        'agencyOrder': 3,
        'stakeholder': {'name': 'Third actual agency'},
      },
      {
        'agencyOrder': 1,
        'stakeholder': {'name': 'Primary actual agency'},
      },
      {
        'agencyOrder': 2,
        'stakeholder': {'name': 'Second actual agency'},
      },
    ],
    'issueReference': {'path': '/issue.pdf', 'name': 'Original issue.pdf'},
    'referenceDocument': {
      'path': '/reference.pdf',
      'name': 'Original reference.pdf',
    },
  };

  test('summary issue retains API metadata and agency order', () {
    final issue = MeetingSummaryIssue(issueJson);
    expect(issue.submittedBy, 'Actual submitter');
    expect(issue.submittedDate, DateTime.utc(2026, 10, 19, 9));
    expect(issue.category, 'Actual category');
    expect(issue.status, 'IN_PROGRESS');
    expect(issue.governmentAgencies, {
      1: 'Primary actual agency',
      2: 'Second actual agency',
      3: 'Third actual agency',
    });
    expect(issue.description, 'Actual issue description');
    expect(issue.descriptionHtml, '<p>Actual issue description</p>');
  });

  test('nested issue fields survive empty outer values and document paths', () {
    final issue = MeetingSummaryIssue({
      'issue': {
        'title': 'Nested issue',
        'user': {'name': 'Nested submitter'},
        'createdAt': '2026-10-18T08:00:00Z',
        'description': '<p>Nested description</p>',
        'recommendations': '<p>Nested recommendation</p>',
        'governmentAgencies': [
          {
            'stakeholder': {'name': 'Nested agency'},
          },
        ],
        'attachment': {'path': '/nested.pdf', 'name': 'Nested original.pdf'},
      },
      'agencies': [],
      'title': null,
      'issueReference': {'path': ' '},
    });
    expect(issue.title, 'Nested issue');
    expect(issue.submittedBy, 'Nested submitter');
    expect(issue.submittedDate, DateTime.utc(2026, 10, 18, 8));
    expect(issue.agency, 'Nested agency');
    expect(issue.attachmentPath, '/nested.pdf');
    expect(issue.attachmentName, 'Nested original.pdf');
    expect(issue.recommendation, 'Nested recommendation');
  });

  testWidgets(
    'private summary issue sheet preserves selected fields and both documents',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
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
                    expect(request.url.path, '/api/v1/meeting-summaries/26');
                    return http.Response(
                      jsonEncode({
                        'success': true,
                        'data': {
                          'id': 26,
                          'meeting': {
                            'title': 'Actual meeting',
                            'meetingDate': '2026-10-19T00:00:00Z',
                            'startTime': '13:30',
                            'location': 'Actual room',
                          },
                          'issues': [
                            issueJson,
                            {
                              'issue': 'Another issue',
                              'submittedBy': 'Another submitter',
                              'submittedDate': '2024-01-01T00:00:00Z',
                            },
                          ],
                        },
                      }),
                      200,
                      headers: {
                        'content-type': 'application/json; charset=utf-8',
                      },
                    );
                  }),
                ),
              ),
            )
            ..setLanguage(AppLanguage.english)
            ..setModuleType(AppModuleType.privateSector);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: MeetingSummaryDetailScreen(id: 26)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1:30 PM'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Actual summary issue'), 250);
      await tester.tap(find.text('Actual summary issue'));
      await tester.pumpAndSettle();
      for (final language in [AppLanguage.english, AppLanguage.khmer]) {
        settings.setLanguage(language);
        await tester.pumpAndSettle();
        final l10n = AppLocalizations(language);
        expect(
          find.text('Actual submitter', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.textContaining(
              l10n.number(2026),
              findRichText: true,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.text('Primary actual agency', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.text('Second actual agency', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.text('Third actual agency', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Original issue.pdf'), findsOneWidget);
        expect(find.text('Original reference.pdf'), findsOneWidget);
        final documents = tester.widgetList<PdfAttachmentPreview>(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(PdfAttachmentPreview),
          ),
        );
        expect(documents.map((doc) => doc.path), [
          '/issue.pdf',
          '/reference.pdf',
        ]);
        expect(find.textContaining('MAFF', findRichText: true), findsNothing);
        expect(
          find.textContaining('Jun 24 2025', findRichText: true),
          findsNothing,
        );
        expect(
          find.textContaining('Another submitter', findRichText: true),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Another issue'), 250);
      await tester.tap(find.text('Another issue'));
      await tester.pumpAndSettle();
      final km = AppLocalizations(AppLanguage.khmer);
      expect(
        find.text('Another submitter', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(km.number(2024), findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Primary actual agency', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('Actual submitter', findRichText: true),
        findsNothing,
      );
      expect(calls, 1);
    },
  );

  testWidgets(
    'missing API metadata stays empty without fabricated date, time or agencies',
    (tester) async {
      final settings = AppSettingsController()
        ..setLanguage(AppLanguage.english)
        ..setModuleType(AppModuleType.privateSector);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: MeetingSummaryDetailScreen(
              summary: MeetingSummary({
                'id': 26,
                'meeting': {},
                'issues': [
                  {'issue': 'Minimal issue'},
                ],
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7:00 AM'), findsNothing);
      await tester.scrollUntilVisible(find.text('Minimal issue'), 250);
      await tester.tap(find.text('Minimal issue'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Submitted Date'),
        ),
        findsOneWidget,
      );
      expect(find.text('Submitted By'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('—')),
        findsWidgets,
      );
      expect(find.textContaining('MAFF', findRichText: true), findsNothing);
      expect(find.textContaining('Not Data', findRichText: true), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
