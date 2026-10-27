import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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
  testWidgets('API categories retain order, status, zero rows and language', (
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
    expect(
      tester.getTopLeft(find.text(data.categories[0].name)).dy,
      lessThan(tester.getTopLeft(find.text(data.categories[1].name)).dy),
    );
    expect(find.byType(FittedBox), findsOneWidget);
    await tester.ensureVisible(find.text('Show more'));
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.text(data.categories.last.name), findsOneWidget);
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
    await tester.ensureVisible(find.text('Show less'));
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(find.text(data.categories.last.name), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mixed statuses stack on one scale without filling smaller totals',
    (tester) async {
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
      expect(width(2, 'inProgress'), closeTo(trackWidth / 2, 0.01));
      expect(tester.takeException(), isNull);
    },
  );
}
