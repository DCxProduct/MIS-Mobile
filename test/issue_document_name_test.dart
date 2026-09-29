import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';
import 'package:gpsf_app/features/cdc_section/issues/issue_detail_screen.dart';
import 'package:gpsf_app/features/shared/issues/data/working_group_issue.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  test(
    'PDF fallback removes upload timestamp and preserves meaningful numbers',
    () {
      expect(
        pdfAttachmentName('/uploads/1789400204856-meeting_doc.pdf'),
        'meeting_doc.pdf',
      );
      expect(
        pdfAttachmentName(
          '/uploads/1789400204856-Meeting%20Request.pdf?token=abc',
        ),
        'Meeting Request.pdf',
      );
      expect(pdfAttachmentName('/uploads/2026-report.pdf'), '2026-report.pdf');
    },
  );

  testWidgets(
    'meeting document displays API filename and keeps uploaded path',
    (tester) async {
      final issue = WorkingGroupIssue.fromJson({
        'id': 14,
        'title': 'Issue',
        'meetingRequest': {
          'meetingRequestLetter': {
            'path': '/uploads/1789400204856-meeting_doc.pdf',
            'name': 'Original meeting request.pdf',
          },
        },
      });
      final settings = AppSettingsController()
        ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: CdcSectionIssueDetailScreen(
              title: issue.title,
              category: issue.category,
              issue: issue,
              generalIssue: true,
            ),
          ),
        ),
      );
      expect(find.text('Original meeting request.pdf'), findsOneWidget);
      final preview = tester.widget<PdfAttachmentPreview>(
        find.byType(PdfAttachmentPreview),
      );
      expect(preview.path, '/uploads/1789400204856-meeting_doc.pdf');
      expect(preview.name, 'Original meeting request.pdf');
    },
  );

  test('document fallback name comes from the same source as its path', () {
    final issue = WorkingGroupIssue.fromJson({
      'id': 14,
      'title': 'Issue',
      'meetingRequest': {
        'meetingRequestLetter': null,
        'documentReference': {
          'path': '/uploads/reference.pdf',
          'name': 'Reference.pdf',
        },
      },
    });
    expect(issue.meetingRequestDocumentPath, '/uploads/reference.pdf');
    expect(issue.meetingRequestDocumentName, 'Reference.pdf');
  });
}
