import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/editor_content.dart';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_secretariat/meetings/summary_issue_details.dart';
import 'package:gpsf_app/features/private_sector/reports/meeting_summary_detail_screen.dart';
import 'package:gpsf_app/features/shared/meetings/data/meeting_summary.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> suppliedResponse() =>
    jsonDecode(
          File('test/fixtures/ministry_summary_14.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  test(
    'summary 14 preserves web documents, participants and selected issue',
    () {
      final data = suppliedResponse()['data'] as Map<String, dynamic>;
      final summary = MeetingSummary(data);
      expect(summary.id, 14);
      expect(summary.pswg, 'Agriculture & Agro-Industry');
      expect(summary.pswgKhName, data['meetingRequest']['pswgKhName']);
      expect(summary.sentBy, 'MAFF');
      expect(summary.governmentAgency, 'MAFF');
      expect(
        summary.meetingDocumentPath,
        data['meeting']['documentReference']['path'],
      );
      expect(
        summary.requestDocumentPath,
        data['meetingRequest']['meetingRequestLetter']['path'],
      );
      expect(summary.summaryDocumentPath, data['documentReference']['path']);
      expect(summary.meetingDocumentSize, 1947246);
      expect(summary.requestDocumentSize, 1947246);
      expect(summary.participants.map((p) => p.group), ['pswg', 'ministry']);
      expect(
        summary.participants.every(
          (p) => p.reporter.isEmpty && p.representative.isEmpty,
        ),
        isTrue,
      );
      final issue = summary.issues.single;
      final source = data['issues'][0];
      expect(issue.number, 'WG01_0018');
      expect(issue.workingGroup, source['wgName']);
      expect(issue.governmentAgencies, {
        1: 'MAFF',
        2: 'GDCE',
        3: 'GDT',
        4: 'MEF',
        5: 'MISTI',
      });
      expect(issue.escalation, 'CEFP');
      expect(issue.status, 'NOT_ADDRESSED');
      expect(issue.submittedBy, 'MAFF');
      expect(issue.submittedDate, DateTime.utc(2026, 11, 10));
      expect(issue.descriptionHtml, source['issueDescription']);
      expect(issue.recommendationHtml, source['recommendation']);
      expect(issue.rgcDecisionHtml, source['rgcDecision']);
      expect(issue.nextStepHtml, source['nextStep']);
      expect(issue.remarkHtml, source['remark']);
      expect(issue.attachmentPath, source['issueReference']['path']);
      expect(issue.referencePath, source['referenceDocument']['path']);
    },
  );

  test('participant names and positions stay in their API groups', () {
    final summary = MeetingSummary({
      'id': 14,
      'pswgReporter': 'PSWG reporter',
      'pswgReporterPosition': 'PSWG reporter position',
      'pswgRepresentative': 'PSWG representative',
      'pswgRepresentativePosition': 'PSWG representative position',
      'ministryReporter': 'Ministry reporter',
      'ministryReporterPosition': 'Ministry reporter position',
      'ministryRepresentative': 'Ministry representative',
      'ministryRepresentativePosition': 'Ministry representative position',
    });
    for (final (index, group) in [(0, 'PSWG'), (1, 'Ministry')]) {
      final participant = summary.participants[index];
      expect(participant.reporter, '$group reporter');
      expect(participant.reporterPosition, '$group reporter position');
      expect(participant.representative, '$group representative');
      expect(
        participant.representativePosition,
        '$group representative position',
      );
    }
  });

  for (final language in [AppLanguage.english, AppLanguage.khmer]) {
    testWidgets('Ministry summary 14 matches web data in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final payload = suppliedResponse();
      final data = payload['data'] as Map<String, dynamic>;
      final calls = <String>[];
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    calls.add(request.url.path);
                    expect(request.url.path, '/api/v1/meeting-summaries/14');
                    return http.Response.bytes(
                      utf8.encode(jsonEncode(payload)),
                      200,
                    );
                  }),
                ),
              ),
            )
            ..setModuleType(AppModuleType.lineMinistry)
            ..setLanguage(language);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: MeetingSummaryDetailScreen(id: 14)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final summaryScroll = find.byType(Scrollable).first;
      for (final (name, path) in [
        (
          'meeting_document_reference.pdf',
          data['meetingRequest']['meetingRequestLetter']['path'],
        ),
        (
          'meeting_request_latter.pdf',
          data['meeting']['documentReference']['path'],
        ),
        ('Meeting_summary_ reference.pdf', data['documentReference']['path']),
      ]) {
        await tester.scrollUntilVisible(
          find.text(name),
          150,
          scrollable: summaryScroll,
        );
        final preview = tester.widget<PdfAttachmentPreview>(
          find.ancestor(
            of: find.text(name),
            matching: find.byType(PdfAttachmentPreview),
          ),
        );
        expect(preview.path, path);
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(
        find.text('WG01_0018'),
        150,
        scrollable: summaryScroll,
      );
      await tester.tap(find.text('WG01_0018'));
      await tester.pumpAndSettle();
      final sheet = find.byType(CdcSummaryIssueDetails);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(
          of: sheet,
          matching: find.text(data['issues'][0]['issue']),
        ),
        findsOneWidget,
      );
      final details = tester.widget<CdcSummaryIssueDetails>(sheet).issue;
      expect(details.agencyLogos, hasLength(5));
      expect(details.escalation, 'CEFP');
      final documents = tester.widgetList<PdfAttachmentPreview>(
        find.descendant(of: sheet, matching: find.byType(PdfAttachmentPreview)),
      );
      expect(documents.map((p) => p.path), [
        details.attachmentPath,
        details.referencePath,
      ]);
      final sheetScroll = find
          .descendant(of: sheet, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.byWidgetPredicate(
          (widget) =>
              widget is EditorContent && widget.data == details.remarkHtml,
        ),
        200,
        scrollable: sheetScroll,
      );
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(sheet)).pop();
      await tester.pumpAndSettle();
      for (final group in ['pswg', 'ministry']) {
        final participant = find.byKey(ValueKey('summary-participant-$group'));
        await tester.scrollUntilVisible(
          participant,
          180,
          scrollable: summaryScroll,
        );
        expect(
          find.descendant(of: participant, matching: find.text('—')),
          findsNWidgets(4),
        );
      }
      expect(calls, ['/api/v1/meeting-summaries/14']);
      expect(tester.takeException(), isNull);
    });
  }
}
