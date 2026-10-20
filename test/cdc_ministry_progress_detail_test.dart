import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_reports_repository.dart';
import 'package:gpsf_app/screens/report/progress_report_detail_loader.dart';
import 'package:gpsf_app/screens/report/report_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final response =
      jsonDecode(
            File(
              'test/fixtures/cdc_ministry_progress_detail.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final data = response['data'] as Map<String, dynamic>;
  ApiClient api() => ApiClient(
    client: MockClient((request) async {
      expect(request.url.path, '/api/v1/progress-reports/2/ministries/1');
      return http.Response(
        jsonEncode(response),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );

  test(
    'maps supplied CDC ministry detail, linked records and all report documents',
    () async {
      final client = api();
      addTearDown(client.close);
      final report = await ProgressReportsRepository(
        client,
      ).getMinistryDetail(2, 1);
      expect(
        report.ministryDisplayName,
        'Ministry of Agriculture, Forestry and Fisheries',
      );
      expect(report.preparedBy, 'MAFF');
      expect(report.reviewedBy, 'CDC G-PSF Secretariat');
      expect(report.cdcStatus, 'COMPLETED');
      expect(report.openIssues.length, 3);
      expect(report.rgcDecisions.length, 2);
      expect(report.description, data['progressReport']['description']);
      expect(report.latestMeeting['meetingDate'], '2026-09-14');
      expect(report.latestMeeting['startTime'], '12:00:00');
      expect(report.approvalDocument, data['attachment']['path']);
      expect(
        report.requestDocument,
        data['progressReport']['requestDocument']['path'],
      );
      for (final meeting in data['progressReport']['meetings'] as List) {
        final file = meeting['documentReference'];
        expect(report.attachmentPaths, contains(file['path']));
        expect(report.documentNames[file['path']], file['name']);
      }
    },
  );

  testWidgets('CDC ministry View Details shows API headers and every tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings =
        AppSettingsController(authRepository: AuthRepository(api()))
          ..setModuleType(AppModuleType.cdcSecretariat)
          ..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(
          home: ProgressReportDetailLoader(id: 2, ministryId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Ministry of Agriculture, Forestry and Fisheries'),
      findsOneWidget,
    );
    expect(
      find.textContaining('CDC G-PSF Secretariat', findRichText: true),
      findsWidgets,
    );
    expect(find.text('Issue_solution_reference.pdf'), findsOneWidget);
    expect(find.text('Approval_progress_report.pdf'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('• Completed')).style?.color,
      const Color(0xFF16A34A),
    );
    expect(find.textContaining('12:00:00'), findsNothing);
    expect(find.text(data['progressReport']['description']), findsOneWidget);
    await tester.ensureVisible(find.text('All Issues'));
    await tester.tap(find.text('All Issues'));
    await tester.pumpAndSettle();
    for (final issue in data['openIssues'] as List) {
      expect(
        find.byKey(ValueKey('report-issue-${issue['id']}')),
        findsOneWidget,
      );
    }
    await tester.ensureVisible(find.text('RGC Decision'));
    await tester.tap(find.text('RGC Decision'));
    await tester.pumpAndSettle();
    for (final decision in data['rgcDecisions'] as List) {
      expect(
        find.byKey(ValueKey('report-rgcDecision-${decision['id']}')),
        findsOneWidget,
      );
    }
    await tester.ensureVisible(find.text('Attachment'));
    await tester.tap(find.text('Attachment'));
    await tester.pumpAndSettle();
    final report = tester
        .widget<ReportDetailScreen>(find.byType(ReportDetailScreen))
        .report!;
    for (final file in report.documentNames.values) {
      expect(find.text(file), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });
}
