import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/features/shared/dashboard/data/pswg_dashboard.dart';
import 'package:gpsf_app/features/shared/dashboard/data/working_group_order.dart';
import 'package:gpsf_app/features/shared/dashboard/data/working_group_summary.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/working_group_list.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final json =
      jsonDecode(
            File(
              'test/fixtures/localized_plenary_dashboard.json',
            ).readAsStringSync().replaceFirst('\uFEFF', ''),
          )
          as Map<String, dynamic>;
  final groups = PswgDashboard.fromJson(
    json['data'] as Map<String, dynamic>,
  ).workingGroups;

  test(
    'Khmer letter order preserves API objects and leaves source untouched',
    () {
      final originalIds = groups.map((g) => g.id).toList();
      final sorted = sortWorkingGroupsByKhmerCode(groups);
      expect(sorted.map((g) => g.id), List.generate(16, (i) => i + 14));
      expect(groups.map((g) => g.id), originalIds);
      for (final group in sorted) {
        expect(
          identical(group, groups.firstWhere((g) => g.id == group.id)),
          isTrue,
        );
      }
      const unknown = WorkingGroupSummary(
        id: 100,
        name: 'Unknown',
        total: 0,
        solved: 0,
        inProgress: 0,
        notAddressed: 0,
      );
      expect(
        sortWorkingGroupsByKhmerCode([unknown, ...groups]).last,
        same(unknown),
      );
    },
  );

  testWidgets('View All expands sorted groups and survives language switches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController()..setLanguage(AppLanguage.khmer);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WorkingGroupList(groups: groups),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('working-group-21')), findsOneWidget);
    expect(find.byKey(const ValueKey('working-group-22')), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('working-group-15'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('working-group-16'))).dy,
      ),
    );
    await tester.ensureVisible(find.text('មើលទាំងអស់'));
    await tester.tap(find.text('មើលទាំងអស់'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('working-group-29')), findsOneWidget);
    settings.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();
    expect(find.text('Tourism'), findsOneWidget);
    expect(find.byKey(const ValueKey('working-group-29')), findsOneWidget);
    await tester.ensureVisible(find.text('View Less'));
    await tester.tap(find.text('View Less'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('working-group-22')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: WorkingGroupList(groups: groups.take(2).toList()),
          ),
        ),
      ),
    );
    expect(find.byType(TextButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
