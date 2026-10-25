import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/screens/issues/issue_detail_screen.dart' as ministry;
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';
import 'package:gpsf_app/core/widgets/editor_content.dart';
import 'package:gpsf_app/features/shared/issues/widgets/issue_agency_logo.dart';
import 'package:gpsf_app/features/shared/issues/widgets/issue_display.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/private_sector/issues/issue_detail_screen.dart';
import 'package:gpsf_app/features/private_sector/issues/issue_progress_report_detail_screen.dart';
import 'package:gpsf_app/features/shared/issues/data/working_group_issue.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final fixture = File(
    'test/fixtures/private_sector_issue_detail.json',
  ).readAsStringSync();

  Future<void> openIssue(
    WidgetTester tester,
    ApiClient api, {
    bool selectProgress = true,
    bool ministryScreen = false,
  }) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController(authRepository: AuthRepository(api))
      ..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    addTearDown(api.close);
    // The list record intentionally omits progressReports.
    final issue = WorkingGroupIssue.fromJson({'id': 1, 'title': 'API issue'});
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: ministryScreen
              ? ministry.IssueDetailScreen(
                  title: issue.title,
                  category: issue.category,
                  issue: issue,
                )
              : IssueDetailScreen(
                  title: issue.title,
                  category: issue.category,
                  issue: issue,
                ),
        ),
      ),
    );
    if (selectProgress) await tester.tap(find.text('Progress Report'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'initial detail GET populates Figma header and descriptions from API',
    (tester) async {
      var calls = 0;
      await openIssue(
        tester,
        ApiClient(
          client: MockClient((request) async {
            if (!request.url.path.contains('/working-group-issues/')) {
              return http.Response('{"success":true,"data":{}}', 200);
            }
            calls++;
            expect(request.url.path, '/api/v1/working-group-issues/1');
            return http.Response.bytes(utf8.encode(fixture), 200);
          }),
        ),
        selectProgress: false,
      );
      final raw = jsonDecode(fixture)['data'];
      expect(calls, 1);
      expect(find.text('Issues Details'), findsOneWidget);
      expect(find.text(raw['title'] as String), findsOneWidget);
      expect(find.text('API issue'), findsNothing);
      expect(find.text('MAFF'), findsOneWidget);
      expect(find.text('Market Access'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(
        tester.widget<IssueAgencyLogo>(find.byType(IssueAgencyLogo)).path,
        raw['governmentAgencies'][0]['stakeholder']['logo'],
      );
      final document = tester.widget<PdfAttachmentPreview>(
        find.byType(PdfAttachmentPreview),
      );
      expect(
        document.path,
        raw['meetingRequest']['meetings'][0]['documentReference'],
      );
      expect(document.name, 'meeting_document_reference.pdf');
      final context = tester.element(find.byType(IssueDetailScreen));
      expect(
        find.text(
          'Submitted Date : ${issueDate(context, DateTime.parse(raw['createdAt'] as String))}',
          findRichText: true,
        ),
        findsOneWidget,
      );
      final description = find.byWidgetPredicate(
        (widget) =>
            widget is EditorContent && widget.data == raw['description'],
      );
      expect(description, findsOneWidget);
      final recommendation = find.byWidgetPredicate(
        (widget) =>
            widget is EditorContent && widget.data == raw['recommendation'],
      );
      await tester.scrollUntilVisible(
        recommendation,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(recommendation, findsOneWidget);
      await tester.tap(find.text('Progress Report'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('MAFF'), findsOneWidget);
      expect(find.text('Report S2 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final ministryScreen in [false, true]) {
    testWidgets(
      'ministry=$ministryScreen fetches detail, shows report and opens all API fields',
      (tester) async {
        var calls = 0;
        final api = ApiClient(
          client: MockClient((request) async {
            if (!request.url.path.contains('/working-group-issues/')) {
              return http.Response('{"success":true,"data":{}}', 200);
            }
            calls++;
            expect(request.method, 'GET');
            expect(request.url.path, '/api/v1/working-group-issues/1');
            return http.Response.bytes(utf8.encode(fixture), 200);
          }),
        );
        await openIssue(tester, api, ministryScreen: ministryScreen);
        expect(calls, 1);
        expect(find.text('Report S2 2026'), findsOneWidget);
        expect(find.text('1 Attachments'), findsOneWidget);
        expect(find.textContaining('2026'), findsWidgets);
        expect(
          find.text('No progress report data is available for this issue.'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Descriptions'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Progress Report'));
        await tester.pumpAndSettle();
        expect(calls, 2);
        await tester.ensureVisible(find.text('View Details'));
        await tester.tap(find.text('View Details'));
        await tester.pumpAndSettle();
        final detail = tester.widget<IssueProgressReportDetailScreen>(
          find.byType(IssueProgressReportDetailScreen),
        );
        final raw = jsonDecode(fixture)['data']['progressReports'][0];
        expect(detail.report.progressReportId, 2);
        expect(detail.report.description, raw['progressSolution']);
        expect(detail.report.indicators, raw['indicators']);
        expect(
          detail.report.implementationChallenges,
          raw['implementationChallenges'],
        );
        expect(detail.report.requests, raw['requests']);
        expect(detail.report.rgcDecision, raw['rgcDecision']);
        expect(detail.report.verificationLink, raw['linkToVerificationSource']);
        expect(find.text('Climate Issue'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('Issue_reference.pdf'),
          400,
          scrollable: find.byType(Scrollable).last,
        );
        final preview = tester.widget<PdfAttachmentPreview>(
          find.byType(PdfAttachmentPreview),
        );
        expect(preview.path, raw['attachment']['path']);
        expect(preview.name, 'Issue_reference.pdf');
        expect(find.text('1.9 MB'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('empty API reports display empty state without demo reports', (
    tester,
  ) async {
    final response = jsonDecode(fixture) as Map<String, dynamic>;
    response['data']['progressReports'] = [];
    await openIssue(
      tester,
      ApiClient(
        client: MockClient(
          (_) async =>
              http.Response.bytes(utf8.encode(jsonEncode(response)), 200),
        ),
      ),
    );
    expect(
      find.text('No progress report data is available for this issue.'),
      findsOneWidget,
    );
    expect(find.text('View Details'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed detail request offers retry and recovers', (
    tester,
  ) async {
    var calls = 0;
    await openIssue(
      tester,
      ApiClient(
        client: MockClient((request) async {
          if (!request.url.path.contains('/working-group-issues/')) {
            return http.Response('{"success":true,"data":{}}', 200);
          }
          calls++;
          return calls == 1
              ? http.Response('{"message":"Failed"}', 500)
              : http.Response.bytes(utf8.encode(fixture), 200);
        }),
      ),
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.text('No progress report data is available for this issue.'),
      findsNothing,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Report S2 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  String responseWithReports(int count) {
    final response = jsonDecode(fixture) as Map<String, dynamic>;
    final original = response['data']['progressReports'][0];
    response['data']['progressReports'] = [
      for (var index = 0; index < count; index++)
        {
          ...Map<String, dynamic>.from(original as Map),
          'progressReportId': index + 2,
          'year': 2026 + index,
        },
    ];
    return jsonEncode(response);
  }

  testWidgets('poll displays all new reports and opens the selected report', (
    tester,
  ) async {
    var count = 1;
    var calls = 0;
    await openIssue(
      tester,
      ApiClient(
        client: MockClient((request) async {
          if (!request.url.path.contains('/working-group-issues/')) {
            return http.Response('{"success":true,"data":{}}', 200);
          }
          calls++;
          return http.Response.bytes(
            utf8.encode(responseWithReports(count)),
            200,
          );
        }),
      ),
    );
    expect(find.text('Report S2 2026'), findsOneWidget);
    count = 3;
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Report S2 2027'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Report S2 2028'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    final lastButton = find.widgetWithText(FilledButton, 'View Details').last;
    await tester.ensureVisible(lastButton);
    await tester.pumpAndSettle();
    await tester.tap(lastButton);
    await tester.pumpAndSettle();
    final detail = tester.widget<IssueProgressReportDetailScreen>(
      find.byType(IssueProgressReportDetailScreen),
    );
    expect(detail.report.progressReportId, 4);
    expect(detail.report.title, 'Report S2 2028');
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 2); // A covered issue screen does not poll.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(calls, 3); // Returning from detail fetches the latest list.
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull to refresh can populate an empty report list', (
    tester,
  ) async {
    var count = 0;
    await openIssue(
      tester,
      ApiClient(
        client: MockClient(
          (_) async =>
              http.Response.bytes(utf8.encode(responseWithReports(count)), 200),
        ),
      ),
    );
    expect(
      find.text('No progress report data is available for this issue.'),
      findsOneWidget,
    );
    count = 2;
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(find.text('Report S2 2026'), findsOneWidget);
    expect(find.text('Report S2 2027'), findsOneWidget);
    expect(
      find.text('No progress report data is available for this issue.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tab reentry and app resume fetch fresh reports without background polling',
    (tester) async {
      var count = 1;
      var calls = 0;
      await openIssue(
        tester,
        ApiClient(
          client: MockClient((request) async {
            if (!request.url.path.contains('/working-group-issues/')) {
              return http.Response('{"success":true,"data":{}}', 200);
            }
            calls++;
            return http.Response.bytes(
              utf8.encode(responseWithReports(count)),
              200,
            );
          }),
        ),
      );
      await tester.tap(find.text('Descriptions'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));
      expect(calls, 1);
      count = 2;
      await tester.tap(find.text('Progress Report'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Report S2 2027'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      expect(calls, 2);
      count = 0;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(calls, 3);
      expect(
        find.text('No progress report data is available for this issue.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a failed background refresh preserves reports and retry gets new data',
    (tester) async {
      var calls = 0;
      await openIssue(
        tester,
        ApiClient(
          client: MockClient((request) async {
            if (!request.url.path.contains('/working-group-issues/')) {
              return http.Response('{"success":true,"data":{}}', 200);
            }
            calls++;
            if (calls == 2) return http.Response('{"message":"Failed"}', 500);
            return http.Response.bytes(
              utf8.encode(responseWithReports(calls == 1 ? 1 : 2)),
              200,
            );
          }),
        ),
      );
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('Report S2 2026'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Report S2 2027'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
