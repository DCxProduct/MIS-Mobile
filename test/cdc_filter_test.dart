import 'package:gpsf_app/translations/app_language.dart';
import 'package:flutter/material.dart';
import 'package:gpsf_app/features/cdc_secretariat/issues/issue_filter_sheet.dart';
import 'package:gpsf_app/features/shared/issues/data/working_group_issue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/features/cdc_secretariat/dashboard/filter_sheet.dart';

void main() {
  test(
    'CDC issue filters combine category, status, organization, year and escalation',
    () {
      final issue = WorkingGroupIssue.fromJson({
        'id': 1,
        'title': 'API issue',
        'category': {'name': 'General'},
        'issueStatus': {'code': 'SAVED', 'name': 'Saved'},
        'stakeholder': {'name': 'Agriculture & Agro-Industry'},
        'createdAt': '2026-09-29T00:00:00.000Z',
        'governmentAgencies': [
          {
            'agencyOrder': 1,
            'stakeholder': {'name': 'CRF'},
          },
        ],
        'plenaryEscalation': true,
      });
      final filters = CdcDashboardFilters({
        'categories': {'Agriculture and Agro-Industry'},
        'status': {'Drafted'},
        'allPswgs': {'CRF'},
        'year': {'2026'},
        'plenaryEscalation': {'Yes'},
      });
      expect(matchesCdcIssueFilters(issue, filters), isTrue);
      filters.values['status'] = {'Solved'};
      expect(matchesCdcIssueFilters(issue, filters), isFalse);
      filters.values['status'] = {'Drafted'};
      filters.values['year'] = {'2025'};
      expect(matchesCdcIssueFilters(issue, filters), isFalse);
      filters.values['year'] = {'2026'};
      filters.values['plenaryEscalation'] = {'No'};
      expect(matchesCdcIssueFilters(issue, filters), isFalse);
      final unknown = WorkingGroupIssue.fromJson({'id': 2, 'title': 'Unknown'});
      expect(matchesCdcIssueFilters(unknown, CdcDashboardFilters()), isTrue);
      expect(
        matchesCdcIssueFilters(
          unknown,
          CdcDashboardFilters({
            'plenaryEscalation': {'No'},
          }),
        ),
        isFalse,
      );
    },
  );

  testWidgets(
    'CDC issue filter shows the design sections and retains applied choices',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController()
        ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      var filters = CdcDashboardFilters();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    final result = await Navigator.of(context)
                        .push<CdcDashboardFilters>(
                          MaterialPageRoute(
                            builder: (_) =>
                                CdcIssueFilterSheet(initial: filters),
                          ),
                        );
                    if (result != null) filters = result;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Category'), findsOneWidget);
      final first = find.byKey(
        const ValueKey('filter-categories-Agriculture and Agro-Industry'),
      );
      final fifth = find.byKey(
        const ValueKey('filter-categories-Banking and Financial Services'),
      );
      expect(tester.getRect(first).left, tester.getRect(fifth).left);
      expect(tester.getRect(first).top, lessThan(tester.getRect(fifth).top));
      await tester.tap(first);
      final status = find.byKey(const ValueKey('filter-status-Drafted'));
      await tester.ensureVisible(status);
      await tester.pumpAndSettle();
      await tester.tap(status);
      final year = find.byKey(const ValueKey('filter-year-2026'));
      await tester.scrollUntilVisible(year, 150);
      await tester.pumpAndSettle();
      await tester.tap(year);
      final escalation = find.byKey(
        const ValueKey('filter-plenaryEscalation-Yes'),
      );
      await tester.scrollUntilVisible(escalation, 150);
      await tester.pumpAndSettle();
      await tester.tap(escalation);
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      expect(filters.values['categories'], {'Agriculture and Agro-Industry'});
      expect(filters.values['status'], {'Drafted'});
      expect(filters.values['year'], {'2026'});
      expect(filters.values['plenaryEscalation'], {'Yes'});
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(first);
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      expect(filters.values['categories'], isEmpty);
      expect(filters.values['status'], {'Drafted'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'filter close clears drafts and applied selections, then reopens',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController()
        ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      var filters = CdcDashboardFilters();
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () async {
                      final result = await Navigator.of(context)
                          .push<CdcDashboardFilters>(
                            MaterialPageRoute<CdcDashboardFilters>(
                              fullscreenDialog: true,
                              builder: (_) =>
                                  CdcDashboardFilterSheet(initial: filters),
                            ),
                          );
                      if (result != null) filters = result;
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      Future<void> open() async {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
      }

      await open();
      final titleRect = tester.getRect(find.text('Filters'));
      final closeRect = tester.getRect(find.byIcon(Icons.close_rounded));
      expect(titleRect.center.dx, closeTo(195, 1));
      expect(closeRect.left, greaterThanOrEqualTo(titleRect.right));
      expect(closeRect.right, greaterThan(350));
      await tester.tap(find.byKey(const ValueKey('filter-status-Solved')));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(filters.count, 0);
      await open();
      await tester.tap(find.byKey(const ValueKey('filter-status-Solved')));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(filters.values['status'], {'Solved'});
      await open();
      expect(filters.values['status'], {'Solved'});
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(filters.values, isEmpty);
      await open();
      expect(find.byIcon(Icons.check), findsNothing);
      await tester.tap(find.byKey(const ValueKey('filter-status-Solved')));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(filters.values['status'], {'Solved'});
      await open();
      await tester.tap(find.byKey(const ValueKey('filter-status-Solved')));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(filters.count, 0);
    },
  );
}
