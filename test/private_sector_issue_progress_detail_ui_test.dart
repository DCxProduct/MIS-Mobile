import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/widgets/editor_content.dart';
import 'package:gpsf_app/features/private_sector/issues/issue_progress_report_detail_screen.dart';
import 'package:gpsf_app/features/shared/issues/data/issue_progress_report.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  testWidgets('detail metadata and expandable content fit a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('KhBattambang')
      ..addFont(rootBundle.load('assets/fonts/KhBattambang.ttf'));
    await font.load();
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final raw = Map<String, dynamic>.from(
      jsonDecode(
            File(
              'test/fixtures/private_sector_issue_detail.json',
            ).readAsStringSync(),
          )['data']['progressReports'][0]
          as Map,
    );
    raw['progressSolution'] = List.filled(
      12,
      raw['progressSolution'],
    ).join('\n');
    raw['indicators'] = List.filled(8, raw['indicators']).join(' ');
    raw['sourceOfVerification'] = 'Report reference';
    final report = IssueProgressReport.fromJson(raw);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'KhBattambang'),
          home: RepaintBoundary(
            key: const ValueKey('preview'),
            child: IssueProgressReportDetailScreen(
              title: 'Climate Issue',
              report: report,
              issueStatus: 'SOLVED',
              meetingDocumentPath: '/uploads/meeting-reference.pdf',
              meetingDocumentName: 'Request Doc',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Report S2 2026'), findsOneWidget);
    expect(find.text('Solved'), findsOneWidget);
    expect(find.text('Request Doc'), findsOneWidget);
    final datePosition = tester.getTopLeft(find.text('Implementation Date'));
    final statusPosition = tester.getTopLeft(find.text('Status :'));
    expect(datePosition.dy, statusPosition.dy);
    expect(statusPosition.dx, greaterThan(datePosition.dx));
    final description = find.byKey(const ValueKey('report-description'));
    expect(tester.widget<EditorContent>(description).maxLines, 12);
    final toggle = find.byKey(const ValueKey('report-description-toggle'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<EditorContent>(description).maxLines, isNull);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<EditorContent>(description).maxLines, 12);

    final indicators = find.byKey(const ValueKey('report-indicators'));
    await tester.ensureVisible(indicators);
    await tester.pumpAndSettle();
    final inlineText = find.descendant(
      of: indicators,
      matching: find.byWidgetPredicate(
        (widget) => widget is Text && widget.textSpan != null,
      ),
    );
    TextSpan action() =>
        (tester.widget<Text>(inlineText).textSpan as TextSpan).children!.last
            as TextSpan;
    expect(action().text, 'Read more');
    (action().recognizer as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();
    expect(action().text, 'Show less');
    (action().recognizer as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();
    expect(action().text, 'Read more');
    final decision = find.byKey(const ValueKey('report-rgcDecision'));
    await tester.scrollUntilVisible(
      decision,
      350,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('RGC Decision'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
