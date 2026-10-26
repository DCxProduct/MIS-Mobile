import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/features/shared/dashboard/data/working_group_summary.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/category_totals_chart.dart';
import 'package:gpsf_app/translations/app_language.dart';

WorkingGroupSummary category(int id, int total) => WorkingGroupSummary(
  id: id,
  name: 'Category $id',
  khmerName: 'ប្រភេទ $id',
  total: total,
  solved: 0,
  inProgress: total,
  notAddressed: 0,
);

void main() {
  testWidgets(
    'category totals use a shared scale, descending order and localized counts',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController()
        ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      final rows = [
        category(1, 1),
        category(2, 4),
        category(3, 0),
        category(4, 2),
      ];
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(body: CategoryTotalsChart(categories: rows)),
          ),
        ),
      );
      double width(int id) =>
          tester.getSize(find.byKey(ValueKey('category-bar-$id'))).width;
      expect(width(2), closeTo(width(4) * 2, 0.01));
      expect(width(2), closeTo(width(1) * 4, 0.01));
      expect(width(3), 0);
      final track = tester
          .getSize(find.byKey(const ValueKey('category-track-2')))
          .width;
      expect(width(2), closeTo(track * 4 / 6, 0.01));
      expect(
        tester.getTopLeft(find.text('Category 2')).dy,
        lessThan(tester.getTopLeft(find.text('Category 4')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Category 4')).dy,
        lessThan(tester.getTopLeft(find.text('Category 1')).dy),
      );
      expect(
        find.text('0'),
        findsOneWidget,
      ); // Axis only, no value on empty bars.
      for (final language in [AppLanguage.khmer, AppLanguage.english]) {
        settings.setLanguage(language);
        await tester.pumpAndSettle();
        final khmer = language == AppLanguage.khmer;
        final label = find.text(khmer ? 'ប្រភេទ 2' : 'Category 2');
        expect(label, findsOneWidget);
        expect(tester.widget<Text>(label).maxLines, isNull);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('category-bar-2')),
            matching: find.text(khmer ? '៤' : '4'),
          ),
          findsOneWidget,
        );
        expect(find.text(khmer ? '៦' : '6'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('zero and empty datasets do not invent category totals', (
    tester,
  ) async {
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    for (final rows in [
      <WorkingGroupSummary>[category(1, 0)],
      <WorkingGroupSummary>[],
    ]) {
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(body: CategoryTotalsChart(categories: rows)),
          ),
        ),
      );
      if (rows.isNotEmpty) {
        expect(
          tester.getSize(find.byKey(const ValueKey('category-bar-1'))).width,
          0,
        );
      } else {
        expect(find.text('Category 1'), findsNothing);
        expect(find.byType(FittedBox), findsNothing);
      }
      expect(tester.takeException(), isNull);
    }
  });
}
