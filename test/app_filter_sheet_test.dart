import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/widgets/filters/app_filter_sheet.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  testWidgets('dashboard years show only their API reporting periods', (
    tester,
  ) async {
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    FilterSelection? applied;
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: AppFilterSheet(
              initial: FilterSelection(),
              sections: const [
                FilterSection(
                  id: 'local.year',
                  title: 'Year',
                  singleSelection: true,
                  options: [
                    FilterOption(value: '2027', label: '2027'),
                    FilterOption(value: '2026', label: '2026'),
                  ],
                ),
                FilterSection(
                  id: 'progressReportId',
                  title: 'Progress Report',
                  singleSelection: true,
                  options: [
                    FilterOption(value: '27', label: 'S2 2027', year: '2027'),
                    FilterOption(value: '26', label: 'S2 2026', year: '2026'),
                  ],
                ),
              ],
              onApply: (value) => applied = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('filter-local.year-2026')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('filter-progressReportId-27')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('filter-progressReportId-26')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('filter-progressReportId-26')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('filter-local.year-2027')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('filter-progressReportId-26')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('filter-progressReportId-27')));
    await tester.pump();
    await tester.tap(find.text('Apply Filters'));
    expect(applied!['local.year'], {'2027'});
    expect(applied!['progressReportId'], {'27'});
    expect(applied!.toQuery(), {'progressReportId': '27'});
  });

  testWidgets('custom filter values support single and exclusive selections', (
    tester,
  ) async {
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final initial = FilterSelection({
      'ministryId': {'1'},
    });
    FilterSelection? applied;
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: AppFilterSheet(
              initial: initial,
              sections: const [
                FilterSection(
                  id: 'ministryId',
                  title: 'Agency',
                  columns: 2,
                  singleSelection: true,
                  options: [
                    FilterOption(value: '1', label: 'MAFF'),
                    FilterOption(value: '4', label: 'MEF'),
                  ],
                ),
                FilterSection(
                  id: 'period',
                  title: 'Reporting period',
                  columns: 3,
                  exclusiveValues: {'all'},
                  options: [
                    FilterOption(value: 'all', label: 'Both'),
                    FilterOption(value: 'first', label: 'S1'),
                    FilterOption(value: 'second', label: 'S2'),
                  ],
                ),
              ],
              onApply: (value) => applied = value,
            ),
          ),
        ),
      ),
    );
    Future<void> tap(String key) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pump();
    }

    await tap('filter-ministryId-4');
    await tap('filter-period-first');
    await tap('filter-period-second');
    await tap('filter-period-all');
    await tester.tap(find.text('Apply Filters'));
    expect(applied!.values, {
      'ministryId': {'4'},
      'period': {'all'},
    });
    expect(initial.values, {
      'ministryId': {'1'},
    });
    final previous = applied!;
    await tap('filter-period-first');
    await tester.tap(find.text('Apply Filters'));
    expect(applied!.values['period'], {'first'});
    expect(previous.values['period'], {'all'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded choices retain selections with a pinned apply button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController()..setLanguage(AppLanguage.khmer);
    addTearDown(settings.dispose);
    final initial = FilterSelection();
    FilterSelection? applied;
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: AppFilterSheet(
              initial: initial,
              compact: true,
              sections: [
                FilterSection(
                  id: 'custom',
                  title: 'ក្រុមការងារ',
                  collapsedItemCount: 2,
                  options: [
                    for (var i = 0; i < 18; i++)
                      FilterOption(value: '$i', label: 'ជម្រើស $i'),
                  ],
                ),
              ],
              onApply: (value) => applied = value,
            ),
          ),
        ),
      ),
    );
    final apply = find.byType(FilledButton);
    final buttonPosition = tester.getRect(apply);
    expect(find.byKey(const ValueKey('filter-custom-17')), findsNothing);
    final expand = find.byKey(const ValueKey('filter-expand-custom'));
    await tester.tap(expand);
    await tester.pumpAndSettle();
    final choice = find.byKey(const ValueKey('filter-custom-17'));
    await tester.ensureVisible(choice);
    await tester.pumpAndSettle();
    await tester.tap(choice);
    await tester.pump();
    expect(tester.getRect(apply), buttonPosition);
    await tester.ensureVisible(expand);
    await tester.tap(expand);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('filter-custom-17')), findsNothing);
    await tester.tap(apply);
    expect(applied!.values['custom'], {'17'});
    expect(initial.count, 0);
    expect(tester.takeException(), isNull);
  });
}
