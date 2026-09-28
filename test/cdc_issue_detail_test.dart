import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/features/cdc_section/issues/issue_detail_screen.dart';
import 'package:gpsf_app/features/shared/issues/data/working_group_issue.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  testWidgets('detail uses selected issue data on a narrow dark screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final issue = WorkingGroupIssue.fromJson({
      'id': 777,
      'title': 'Selected issue',
      'category': 'Legislation',
      'description': 'Selected issue description',
      'recommendation': 'Selected issue recommendation',
      'issueStatus': {'code': 'SOLVED', 'name': 'Solved'},
      'governmentAgencies': [
        {
          'agencyOrder': 1,
          'stakeholder': {'name': 'Selected agency'},
        },
      ],
      'attachment': {'path': '/files/selected-issue.pdf'},
      'createdAt': '2026-09-01T00:00:00Z',
    });
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: CdcSectionIssueDetailScreen(
            title: issue.title,
            category: issue.category,
            issue: issue,
          ),
        ),
      ),
    );
    expect(find.text('Selected agency'), findsOneWidget);
    expect(find.text('Solved'), findsOneWidget);
    expect(find.text('Legislation'), findsOneWidget);
    expect(find.text('selected-issue.pdf'), findsOneWidget);
    expect(find.text('Selected issue description'), findsOneWidget);
    expect(
      find.textContaining('Selected issue recommendation', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('MAFF'), findsNothing);
    expect(find.text('200 KB'), findsNothing);
    expect(
      find.textContaining('agreed to have joint inspections'),
      findsNothing,
    );
    await tester.ensureVisible(find.text('Link to Verification Source'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
