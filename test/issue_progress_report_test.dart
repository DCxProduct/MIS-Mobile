import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/features/cdc_section/issues/issue_detail_screen.dart';
import 'package:gpsf_app/features/cdc_section/issues/progress_report_data_detail_screen.dart';
import 'package:gpsf_app/features/shared/issues/data/working_group_issue.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  WorkingGroupIssue issueWithReports() => WorkingGroupIssue.fromJson({
    'id': 14,
    'title': 'Issue with actual report',
    'progressReports': [
      {
        'progressReport': {'semester': 'S1', 'year': 2025},
        'implementationDate': '2025-10-30T14:00:00Z',
        'referenceName': 'Reference from API',
        'description': '<p>Report detail from API</p>',
        'attachments': [
          {'path': '/uploads/report-1.pdf'},
          {'path': '/uploads/report-2.pdf'},
        ],
      },
    ],
  });

  test(
    'issue detail parses linked progress report and real attachment count',
    () {
      final reports = issueWithReports().progressReports;
      expect(reports, hasLength(1));
      expect(reports.single.title, 'Report S1 2025');
      expect(reports.single.referenceName, 'Reference from API');
      expect(reports.single.attachmentPaths, hasLength(2));
      expect(reports.single.description, 'Report detail from API');
    },
  );

  testWidgets('issue report card and View Details show API data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final issue = issueWithReports();
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
    await tester.ensureVisible(find.text('Report S1 2025'));
    await tester.pumpAndSettle();
    expect(find.text('Reference from API'), findsOneWidget);
    final reference = tester.widget<Text>(find.text('Reference from API'));
    expect(reference.maxLines, 1);
    expect(reference.overflow, TextOverflow.ellipsis);
    expect(find.text('2 Attachments'), findsOneWidget);
    expect(find.textContaining('2025'), findsWidgets);
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();
    expect(find.text('Report detail from API'), findsOneWidget);
    expect(find.text('report-1.pdf'), findsOneWidget);
    expect(find.text('report-2.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'empty report list stays empty instead of inserting a sample report',
    () {
      final issue = WorkingGroupIssue.fromJson({
        'id': 15,
        'title': 'No reports',
        'progressReports': [],
      });
      expect(issue.progressReports, isEmpty);
    },
  );

  test('issue-level progress fields do not create a linked report', () {
    final issue = WorkingGroupIssue.fromJson({
      'id': 5,
      'title': 'General issue',
      'category': {'name': 'General'},
      'progressReports': [],
      'attachment': {
        'path': '/uploads/issues/issue-document.pdf',
        'name': 'Issue document',
      },
      'dateOfIssueSolution': '2026-09-15',
      'progressSolution': '<p>Progress from issue API</p>',
      'indicators': 'Indicators from issue API',
      'implementationChallenges': 'Challenges from issue API',
      'nextStep': 'Next step from issue API',
      'rgcDecision': 'Decision from issue API',
    });
    expect(issue.progressReports, isEmpty);
    final progress = issue.issueProgress!;
    expect(progress.implementationDate, DateTime(2026, 9, 15));
    expect(progress.description, 'Progress from issue API');
    expect(progress.nextStep, 'Next step from issue API');
    expect(progress.attachmentPaths, isEmpty);
  });

  test('an RGC decision alone does not create a progress report', () {
    final issue = WorkingGroupIssue.fromJson({
      'id': 12,
      'title': 'Issue with decision only',
      'rgcDecision': 'Decision',
      'nextStep': 'Next step',
    });
    expect(issue.progressReports, isEmpty);
  });

  testWidgets('issue without linked reports shows the empty message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final issue = WorkingGroupIssue.fromJson({
      'id': 5,
      'title': 'General issue',
      'dateOfIssueSolution': '2026-09-15',
      'progressSolution': 'Progress from issue API',
      'nextStep': 'Next step from issue API',
    });
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
    await tester.pumpAndSettle();
    expect(find.text('Progress Report'), findsNothing);
    expect(find.text('View Details'), findsNothing);
    expect(
      find.text('No progress report data is available for this issue.'),
      findsOneWidget,
    );
    expect(find.text('Progress from issue API'), findsNothing);
    expect(find.text('Next step from issue API'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report detail fits a narrow phone and scrolls to RGC decision', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final report = WorkingGroupIssue.fromJson({
      'id': 5,
      'title': 'Long issue title for a narrow phone',
      'progressReports': [
        {
          'year': 2026,
          'semester': 'S2',
          'dateOfIssueSolution': '2026-09-15',
          'progressSolution': List.filled(40, 'Progress detail').join(' '),
          'indicators': 'Indicators',
          'implementationChallenges': 'Challenges',
          'requests': 'Requests',
          'rgcDecision': 'Decision from report API',
        },
      ],
    }).progressReports.single;
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: CdcIssueProgressReportDataDetailScreen(
            report: report,
            issueTitle: 'Long issue title for a narrow phone',
            issueStatus: 'In Progress',
            meetingDocumentPath: '/uploads/request.pdf',
            meetingDocumentName: 'Request.pdf',
          ),
        ),
      ),
    );
    expect(find.text('Request.pdf'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();
    final decision = find.textContaining(
      'Decision from report API',
      findRichText: true,
    );
    await tester.scrollUntilVisible(
      decision,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('cdc-progress-report-data-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(decision, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
