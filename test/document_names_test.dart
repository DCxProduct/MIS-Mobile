import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';
import 'package:gpsf_app/features/private_sector/meetings/meeting_request_detail_screen.dart'
    as meeting;
import 'package:gpsf_app/features/private_sector/reports/meeting_summary_detail_screen.dart'
    as summary;
import 'package:gpsf_app/features/shared/meetings/data/meeting_request.dart';
import 'package:gpsf_app/features/shared/meetings/data/meeting_summary.dart';
import 'package:gpsf_app/features/shared/meetings/data/plenary.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_report.dart';
import 'package:gpsf_app/features/shared/issues/data/issue_progress_report.dart';
import 'package:gpsf_app/screens/report/plenary_detail_screen.dart';
import 'package:gpsf_app/screens/report/report_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  test(
    'multiple issue report files retain their individual original names',
    () {
      final report = IssueProgressReport.fromJson({
        'attachment': {'path': '/primary.pdf', 'name': 'Primary original.pdf'},
        'attachments': [
          {'path': '/secondary.pdf', 'name': 'Secondary original.pdf'},
          {
            'path': '/third.pdf',
            'originalName': 'Third original.pdf',
            'name': 'generated.pdf',
          },
        ],
      });
      expect(report.attachmentNames, {
        '/primary.pdf': 'Primary original.pdf',
        '/secondary.pdf': 'Secondary original.pdf',
        '/third.pdf': 'Third original.pdf',
      });
    },
  );
  test(
    'document titles prefer original names and fall back to decoded path names',
    () {
      expect(
        pdfAttachmentName('/uploads/random.pdf', name: ' Original report.pdf '),
        'Original report.pdf',
      );
      expect(
        pdfAttachmentName(
          '/uploads/1789400204856-Meeting%20Request.pdf?token=abc#page=1',
          name: ' ',
        ),
        'Meeting Request.pdf',
      );
      expect(pdfAttachmentName('/uploads/ឯកសារ.pdf#page=1'), 'ឯកសារ.pdf');
      expect(pdfAttachmentName(''), '—');
    },
  );

  test('models retain names with the exact documents they belong to', () {
    final report = ProgressReport({
      'id': 1,
      'ministryInformation': {
        'approvalProgressReport': {
          'path': '/approval.pdf',
          'name': 'Approval original.pdf',
        },
      },
      'cdcInformation': {
        'requestDocument': {
          'path': '/request.pdf',
          'originalName': 'Request original.pdf',
          'name': 'generated.pdf',
        },
      },
    });
    expect(
      report.documentNames[report.approvalDocument],
      'Approval original.pdf',
    );
    expect(
      report.documentNames[report.requestDocument],
      'Request original.pdf',
    );
    final plenary = Plenary({
      'id': 1,
      'documentReference': {
        'path': '/plenary.pdf',
        'name': 'Plenary original.pdf',
      },
    });
    expect(plenary.documentReference, '/plenary.pdf');
    expect(plenary.documentReferenceName, 'Plenary original.pdf');
    expect(plenary.attachmentCount, 1);
  });

  for (final useRequest in [false, true]) {
    testWidgets(
      'summary displays filename from ${useRequest ? 'request' : 'meeting'} metadata',
      (tester) async {
        final settings = AppSettingsController();
        addTearDown(settings.dispose);
        final item = MeetingSummary({
          'id': 1,
          'summaryTitle': 'Summary',
          'meeting': {
            'documentReference': {
              'path': '/meeting.pdf',
              'name': 'Meeting original.pdf',
            },
          },
          if (useRequest)
            'meetingRequest': {
              'meetingRequestLetter': {
                'path': '/request.pdf',
                'originalName': 'Request original.pdf',
                'name': 'generated.pdf',
              },
            },
        });
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: summary.MeetingSummaryDetailScreen(summary: item),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final filename = useRequest
            ? 'Request original.pdf'
            : 'Meeting original.pdf';
        final path = useRequest ? '/request.pdf' : '/meeting.pdf';
        expect(find.text(filename), findsOneWidget);
        final preview = tester.widget<PdfAttachmentPreview>(
          find.byType(PdfAttachmentPreview),
        );
        expect(preview.path, path);
        expect(preview.name, filename);
        settings.setLanguage(AppLanguage.english);
        await tester.pumpAndSettle();
        expect(find.text(filename), findsOneWidget);
        expect(find.text('Request Doc'), findsNothing);
        expect(find.text('200 KB'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('meeting filename falls back to path when API name is missing', (
    tester,
  ) async {
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    final request = MeetingRequest({
      'id': 1,
      'title': 'Meeting',
      'meetingRequestLetter': {
        'path': '/uploads/1789400204856-original%20meeting.pdf',
      },
    });
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: meeting.MeetingRequestDetailScreen(
            title: request.title,
            request: request,
          ),
        ),
      ),
    );
    expect(find.text('original meeting.pdf'), findsOneWidget);
    expect(
      tester
          .widget<PdfAttachmentPreview>(find.byType(PdfAttachmentPreview))
          .name,
      'original meeting.pdf',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('report headers and attachment tab show API names', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final report = ProgressReport({
      'id': 1,
      'title': 'Report',
      'ministryInformation': {
        'approvalProgressReport': {
          'path': '/approval.pdf',
          'name': 'Approval original.pdf',
        },
      },
      'cdcInformation': {
        'requestDocument': {
          'path': '/request.pdf',
          'name': 'Request original.pdf',
        },
      },
    });
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: ReportDetailScreen(title: report.title, report: report),
        ),
      ),
    );
    expect(find.text('Approval original.pdf'), findsOneWidget);
    expect(find.text('Request original.pdf'), findsOneWidget);
    await tester.ensureVisible(find.text('Attachment'));
    await tester.tap(find.text('Attachment'));
    await tester.pumpAndSettle();
    expect(find.text('Approval original.pdf'), findsWidgets);
    expect(find.text('Request original.pdf'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long original plenary filename fits a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    const filename =
        'Original plenary meeting documentation for October 2026.pdf';
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(
          home: PlenaryDetailScreen(
            title: 'Plenary',
            documentReference: '/plenary.pdf',
            documentReferenceName: filename,
          ),
        ),
      ),
    );
    expect(find.text(filename), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
