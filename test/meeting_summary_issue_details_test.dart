import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
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
    'summary detail API fills sender and date without changing the UI',
    (tester) async {
      var calls = 0;
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              calls++;
              expect(request.url.path, '/api/v1/meeting-summaries/4');
              return http.Response(
                jsonEncode({'success': true, 'data': webSummary}),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: MeetingSummaryDetailScreen(id: 4)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('9:00 AM'), findsOneWidget);
      await tester.tap(find.text('Problems on direct flights to Cambodia'));
      await tester.pumpAndSettle();
      expect(
        find.text('Submitted By : MoT', findRichText: true),
        findsOneWidget,
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
        findsNothing,
      );
      settings.setLanguage(AppLanguage.khmer);
      await tester.pumpAndSettle();
      expect(
        find.text(
          '${AppLocalizations(AppLanguage.khmer).text('submittedBy')} : MoT',
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
    'API summary issue sheet uses selected record fields in the original layout',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      final settings = AppSettingsController(
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
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: MeetingSummaryDetailScreen(id: 26)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1:30 PM'), findsOneWidget);
      await tester.tap(find.text('Actual summary issue'));
      await tester.pumpAndSettle();
      for (final language in [AppLanguage.english, AppLanguage.khmer]) {
        settings.setLanguage(language);
        await tester.pumpAndSettle();
        final l10n = AppLocalizations(language);
        expect(
          find.text(
            '${l10n.text('submittedBy')} : Actual submitter',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.textContaining('2026', findRichText: true),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            '${l10n.text('governmentAgency')} : Primary actual agency',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            '${l10n.text('governmentSecondAgency')} : Second actual agency',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            '${l10n.text('governmentThirdAgency')} : Third actual agency',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(find.text('Original issue.pdf'), findsOneWidget);
        expect(find.text('Original reference.pdf'), findsNothing);
        final documents = tester.widgetList<PdfAttachmentPreview>(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(PdfAttachmentPreview),
          ),
        );
        expect(documents.map((doc) => doc.path), ['/issue.pdf']);
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
      await tester.tap(find.text('Another issue'));
      await tester.pumpAndSettle();
      final km = AppLocalizations(AppLanguage.khmer);
      expect(
        find.text(
          '${km.text('submittedBy')} : Another submitter',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.textContaining('2024', findRichText: true), findsOneWidget);
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
        ..setLanguage(AppLanguage.english);
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
      await tester.tap(find.text('Minimal issue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Submitted Date : —', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Submitted By : —', findRichText: true), findsOneWidget);
      expect(find.textContaining('MAFF', findRichText: true), findsNothing);
      expect(find.textContaining('Not Data', findRichText: true), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
