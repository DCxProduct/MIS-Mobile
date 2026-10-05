import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/widgets/filters/api_filter_sheet.dart';
import 'package:gpsf_app/core/widgets/filters/app_filter_sheet.dart';
import 'package:gpsf_app/features/cdc_section/dashboard/working_group_filter_sheet.dart';
import 'package:gpsf_app/features/cdc_secretariat/dashboard/filter_sheet.dart';
import 'package:gpsf_app/features/cdc_secretariat/issues/issue_filter_sheet.dart';
import 'package:gpsf_app/features/cdc_secretariat/reports/report_filter_sheet.dart';
import 'package:gpsf_app/translations/app_language.dart';

const sections = [
  FilterSection(
    id: 'status',
    title: 'Status',
    options: [
      FilterOption(value: 'Solved', label: 'Solved'),
      FilterOption(value: 'In Progress', label: 'In Progress'),
    ],
  ),
];

void main() {
  final builders = <String, Widget Function(FilterSelection)>{
    'common': (initial) => AppFilterSheet(initial: initial, sections: sections),
    'API': (initial) =>
        ApiFilterSheet(initial: initial, load: () async => sections),
    'dashboard': (initial) => CdcDashboardFilterSheet(initial: initial),
    'working-group dashboard': (initial) =>
        CdcWorkingGroupDashboardFilterSheet(initial: initial),
    'issues': (initial) => CdcIssueFilterSheet(initial: initial),
    'reports': (initial) => CdcReportFilterSheet(initial: initial),
    'loading API': (initial) => ApiFilterSheet(
      initial: initial,
      load: () => Completer<List<FilterSection>>().future,
    ),
    'failed API': (initial) => ApiFilterSheet(
      initial: initial,
      load: () async => throw StateError('Catalog unavailable'),
    ),
  };
  for (final entry in builders.entries) {
    testWidgets(
      '${entry.key}: X clears all applied filters and reopening stays empty',
      (tester) async {
        final settings = AppSettingsController()
          ..setLanguage(AppLanguage.english);
        addTearDown(settings.dispose);
        var selection = FilterSelection({
          'status': {'Solved'},
          'year': {'2026'},
          'local.workingGroup': {'Agriculture & Agro-Industry'},
        });
        final previous = selection;
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: StatefulBuilder(
                builder: (context, setState) {
                  return Scaffold(
                    body: Column(
                      children: [
                        Text('Active filters: ${selection.count}'),
                        TextButton(
                          onPressed: () async {
                            final result = await Navigator.of(context)
                                .push<FilterSelection>(
                                  MaterialPageRoute(
                                    builder: (_) => entry.value(selection),
                                  ),
                                );
                            if (result != null) {
                              setState(() => selection = result);
                            }
                          },
                          child: const Text('Open'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        if (entry.key == 'loading API') {
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        } else {
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Active filters: 0'), findsOneWidget);
        expect(selection.values, isEmpty);
        expect(selection.toQuery(), isEmpty);
        expect(selection.hasLocalFilters, isFalse);
        expect(previous.count, 3);
        await tester.tap(find.text('Open'));
        if (entry.key == 'loading API') {
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        } else {
          await tester.pumpAndSettle();
        }
        expect(find.byIcon(Icons.check), findsNothing);
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'embedded callbacks receive empty filters and clear pending choices',
    (tester) async {
      final settings = AppSettingsController()
        ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      FilterSelection? applied;
      var closed = false;
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: AppFilterSheet(
                initial: FilterSelection({
                  'status': {'Solved'},
                }),
                sections: sections,
                onApply: (selection) => applied = selection,
                onClose: () {
                  expect(applied!.count, 0);
                  closed = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('filter-status-In Progress')));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsNWidgets(2));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(closed, isTrue);
      expect(applied!.values, isEmpty);
      expect(find.byIcon(Icons.check), findsNothing);
    },
  );
}
