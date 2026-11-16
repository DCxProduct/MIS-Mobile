import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/features/private_sector/dashboard/tabs/plenary_categories_tab.dart';
import 'package:gpsf_app/features/shared/dashboard/data/pswg_dashboard.dart';
import 'package:gpsf_app/features/shared/dashboard/data/working_group_summary.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/pswg_live_dashboard.dart';
import 'package:gpsf_app/translations/app_language.dart';

Widget chart(AppSettingsController settings, PswgDashboard data) => AppSettings(
  controller: settings,
  child: MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: PswgDataScope(data: data, child: const PlenaryCategoriesTab()),
      ),
    ),
  ),
);

void main() {
  testWidgets('API categories hide zero rows and retain status and language', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final json =
        jsonDecode(
              File(
                'test/fixtures/localized_plenary_dashboard.json',
              ).readAsStringSync().replaceFirst('\uFEFF', ''),
            )
            as Map<String, dynamic>;
    final data = PswgDashboard.fromJson(json['data'] as Map<String, dynamic>);
    await tester.pumpWidget(chart(settings, data));
    final track = find.byKey(const ValueKey('plenary-category-track-5'));
    final active = find.byKey(const ValueKey('plenary-category-5-inProgress'));
    expect(tester.getSize(active).width, tester.getSize(track).width);
    expect(
      tester
          .widget<ColoredBox>(
            find.descendant(of: active, matching: find.byType(ColoredBox)),
          )
          .color,
      const Color(0xFFF1B128),
    );
    expect(
      find.byKey(const ValueKey('plenary-category-5-solved')),
      findsNothing,
    );
    expect(find.text(data.categories[16].name), findsNothing);
    for (final row in data.categories.where((row) => row.total == 0)) {
      expect(
        find.byKey(ValueKey('plenary-category-track-${row.id}')),
        findsNothing,
      );
      expect(find.text(row.name), findsNothing);
    }
    expect(find.byType(FittedBox), findsOneWidget);
    expect(find.text('Show more'), findsNothing);
    settings.setLanguage(AppLanguage.khmer);
    await tester.pumpAndSettle();
    expect(find.text('អាកាសធាតុ'), findsOneWidget);
    expect(
      find.descendant(of: active, matching: find.text('១')),
      findsOneWidget,
    );
    expect(find.text('Climate'), findsNothing);
    expect(tester.takeException(), isNull);
    settings.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsNothing);
    expect(find.text(data.categories.last.name), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'nonempty categories fill each row with readable counts and exact tooltip percentages',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController()
        ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      final data = PswgDashboard(
        cards: {},
        workingGroups: [],
        agencies: [],
        categories: const [
          WorkingGroupSummary(
            id: 1,
            name: 'Mixed',
            total: 4,
            solved: 2,
            inProgress: 1,
            notAddressed: 1,
          ),
          WorkingGroupSummary(
            id: 2,
            name: 'Smaller',
            total: 2,
            solved: 0,
            inProgress: 2,
            notAddressed: 0,
          ),
          WorkingGroupSummary(
            id: 3,
            name: 'Narrow',
            total: 51,
            solved: 50,
            inProgress: 1,
            notAddressed: 0,
          ),
          WorkingGroupSummary(
            id: 4,
            name: 'Empty',
            total: 0,
            solved: 0,
            inProgress: 0,
            notAddressed: 0,
          ),
        ],
      );
      await tester.pumpWidget(chart(settings, data));
      final trackWidth = tester
          .getSize(find.byKey(const ValueKey('plenary-category-track-1')))
          .width;
      double width(int id, String status) => tester
          .getSize(find.byKey(ValueKey('plenary-category-$id-$status')))
          .width;
      expect(width(1, 'solved'), closeTo(trackWidth / 2, 0.01));
      expect(width(1, 'inProgress'), closeTo(trackWidth / 4, 0.01));
      expect(width(1, 'notAddressed'), closeTo(trackWidth / 4, 0.01));
      expect(width(2, 'inProgress'), closeTo(trackWidth, 0.01));
      for (final (id, status) in [
        (1, 'notAddressed'),
        (2, 'inProgress'),
        (3, 'inProgress'),
      ]) {
        expect(
          tester
              .getTopRight(find.byKey(ValueKey('plenary-category-$id-$status')))
              .dx,
          closeTo(
            tester
                .getTopRight(find.byKey(ValueKey('plenary-category-track-$id')))
                .dx,
            0.01,
          ),
        );
      }
      expect(width(3, 'inProgress'), greaterThanOrEqualTo(18));
      expect(
        width(3, 'solved') + width(3, 'inProgress'),
        closeTo(trackWidth, 0.01),
      );
      expect(
        find.byKey(const ValueKey('plenary-category-track-4')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('plenary-category-4-solved')),
        findsNothing,
      );
      expect(find.text('(0)'), findsNothing);
      expect(find.text('Empty'), findsNothing);
      final narrow = find.byKey(
        const ValueKey('plenary-category-3-inProgress'),
      );
      expect(
        find.descendant(of: narrow, matching: find.text('1')),
        findsOneWidget,
      );
      await tester.tap(narrow);
      await tester.pumpAndSettle();
      expect(find.textContaining('1 (1.96%)'), findsOneWidget);
      Tooltip.dismissAllToolTips();
      await tester.pumpAndSettle();
      expect(find.text('(4)'), findsOneWidget);
      expect(find.text('(2)'), findsOneWidget);
      final solved = find.byKey(const ValueKey('plenary-category-1-solved'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(319, 699));
      await mouse.moveTo(tester.getCenter(solved));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Mixed · Solved\n2 (50.00%)'), findsOneWidget);
      await mouse.moveTo(const Offset(319, 699));
      await tester.pumpAndSettle();
      await mouse.removePointer();
      for (final status in ['inProgress', 'notAddressed']) {
        await tester.tap(find.byKey(ValueKey('plenary-category-1-$status')));
        await tester.pumpAndSettle();
        expect(find.textContaining('1 (25.00%)'), findsOneWidget);
        Tooltip.dismissAllToolTips();
        await tester.pumpAndSettle();
      }
      await tester.tap(
        find.byKey(const ValueKey('plenary-category-2-inProgress')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('2 (100.00%)'), findsOneWidget);
      Tooltip.dismissAllToolTips();
      await tester.pumpAndSettle();
      settings.setLanguage(AppLanguage.khmer);
      await tester.pumpAndSettle();
      expect(find.text('(៤)'), findsOneWidget);
      await tester.tap(solved);
      await tester.pumpAndSettle();
      expect(find.textContaining('២ (៥០.០០%)'), findsOneWidget);
      Tooltip.dismissAllToolTips();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
