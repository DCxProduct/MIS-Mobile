import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/features/shared/dashboard/data/pswg_dashboard.dart';
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
  testWidgets('overview category order, values and scale match Web', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rows = PswgDashboard.fromJson(
      jsonDecode(
            File('test/fixtures/overview_live.json').readAsStringSync(),
          )['data']
          as Map<String, dynamic>,
    ).categories;
    final originalIds = rows.map((row) => row.id).toList();
    const expected = [
      ('Regulation', 104),
      ('Governance', 105),
      ('Procedure', 46),
      ('Taxation', 34),
      ('Legislation', 34),
      ('Licensing', 15),
      ('Market Access', 10),
      ('Finance', 13),
      ('Policy', 16),
      ('Human Resources', 10),
      ('Digital / IT', 11),
      ('Infrastructure', 4),
      ('Trade', 2),
      ('Customs', 5),
      ('Security', 2),
      ('Strategy', 12),
      ('Communication', 1),
    ];
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryTotalsChart(categories: rows),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Strategy'), findsOneWidget);
    expect(find.text('Communication'), findsNothing);
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    for (final language in [AppLanguage.english, AppLanguage.khmer]) {
      settings.setLanguage(language);
      await tester.pumpAndSettle();
      String localized(int value) => language == AppLanguage.english
          ? '$value'
          : '$value'
                .split('')
                .map((digit) => '០១២៣៤៥៦៧៨៩'[int.parse(digit)])
                .join();
      var previousY = -1.0;
      for (final (name, count) in expected) {
        final row = rows.singleWhere((row) => row.name == name);
        expect(row.total, count);
        final label = find.byKey(ValueKey('category-value-${row.id}'));
        expect(tester.widget<Text>(label).data, localized(count));
        final y = tester.getTopLeft(label).dy;
        expect(y, greaterThan(previousY));
        previousY = y;
        final bar = tester.getSize(
          find.byKey(ValueKey('category-bar-${row.id}')),
        );
        final track = tester.getSize(
          find.byKey(ValueKey('category-track-${row.id}')),
        );
        if (count >= 34) {
          expect(bar.width, closeTo(track.width * count / 105, 0.01));
        }
        final labelRect = tester.getRect(label);
        final barRect = tester.getRect(
          find.byKey(ValueKey('category-bar-${row.id}')),
        );
        expect(labelRect.left, greaterThanOrEqualTo(barRect.left));
        expect(labelRect.right, lessThanOrEqualTo(barRect.right));
      }
      for (var i = 0; i <= 3; i++) {
        expect(
          tester.widget<Text>(find.byKey(ValueKey('category-axis-$i'))).data,
          localized(i * 35),
        );
      }
      expect(tester.takeException(), isNull);
    }
    expect(rows.map((row) => row.id), originalIds);
    expect(rows.fold<int>(0, (total, row) => total + row.total), 424);
  });

  testWidgets('small category counts remain readable inside colored bars', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await (FontLoader(
      'KhBattambang',
    )..addFont(rootBundle.load('assets/fonts/KhBattambang.ttf'))).load();
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    for (final language in [AppLanguage.english, AppLanguage.khmer]) {
      settings.setLanguage(language);
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              theme: ThemeData(
                brightness: brightness,
                fontFamily: 'KhBattambang',
              ),
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
                child: Scaffold(
                  body: CategoryTotalsChart(
                    categories: [
                      for (final total in [105, 16, 10, 2, 1])
                        category(total, total),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final total in [16, 10, 2, 1]) {
          final label = find.byKey(ValueKey('category-value-$total'));
          final labelRect = tester.getRect(label);
          final barRect = tester.getRect(
            find.byKey(ValueKey('category-bar-$total')),
          );
          final trackRect = tester.getRect(
            find.byKey(ValueKey('category-track-$total')),
          );
          expect(labelRect.left, greaterThanOrEqualTo(barRect.left + 3.9));
          expect(labelRect.right, lessThanOrEqualTo(barRect.right - 3.9));
          expect(labelRect.right, lessThanOrEqualTo(trackRect.right));
          expect(labelRect.top, greaterThanOrEqualTo(trackRect.top));
          expect(labelRect.bottom, lessThanOrEqualTo(trackRect.bottom));
          expect(tester.widget<Text>(label).style!.fontSize, 12);
        }
        final largeBar = tester.getRect(
          find.byKey(const ValueKey('category-bar-105')),
        );
        final largeLabel = tester.getRect(
          find.byKey(const ValueKey('category-value-105')),
        );
        expect(largeLabel.right, lessThan(largeBar.right));
        expect(largeLabel.left, greaterThan(largeBar.left));
        expect(find.byType(FittedBox), findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
    'category totals use the maximum scale and preserve unknown category order',
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
      expect(find.text('Category 3'), findsNothing);
      expect(find.byKey(const ValueKey('category-track-3')), findsNothing);
      expect(find.byKey(const ValueKey('category-bar-3')), findsNothing);
      final track = tester
          .getSize(find.byKey(const ValueKey('category-track-2')))
          .width;
      expect(width(2), closeTo(track, 0.01));
      expect(
        tester.getTopLeft(find.text('Category 1')).dy,
        lessThan(tester.getTopLeft(find.text('Category 2')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Category 2')).dy,
        lessThan(tester.getTopLeft(find.text('Category 4')).dy),
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
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('category-axis-3')))
              .data,
          khmer ? '៤' : '4',
        );
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
      expect(find.text('Category 1'), findsNothing);
      expect(find.byKey(const ValueKey('category-track-1')), findsNothing);
      expect(find.byType(FittedBox), findsNothing);
      expect(find.text('No issues found.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
