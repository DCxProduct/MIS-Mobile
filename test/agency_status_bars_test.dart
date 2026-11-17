import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/widgets/filters/filter_models.dart';
import 'package:gpsf_app/features/shared/dashboard/data/dashboard_repository.dart';
import 'package:gpsf_app/features/shared/dashboard/data/dashboard_snapshot.dart';
import 'package:gpsf_app/features/shared/dashboard/data/pswg_dashboard.dart';
import 'package:gpsf_app/features/shared/dashboard/data/working_group_summary.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/agency_status_bars.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  testWidgets(
    'PSWG agencies use English abbreviations when Khmer abbreviations are null or blank',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await (FontLoader(
        'KhBattambang',
      )..addFont(rootBundle.load('assets/fonts/KhBattambang.ttf'))).load();
      final json =
          jsonDecode(
                File(
                  'test/fixtures/pswg_khmer_agencies.json',
                ).readAsStringSync(),
              )['data']
              as Map<String, dynamic>;
      final sourceAgencies = json['byPrimaryAgency'] as List;
      sourceAgencies.first['agencyKhAbbreviation'] = '  ';
      final dashboard = PswgDashboard.fromJson(
        json,
      ).filtered(FilterSelection());
      expect(dashboard.cards['totalIssues'], 245);
      expect(dashboard.cards['solved'], 218);
      expect(dashboard.cards['inProgress'], 27);
      final settings = AppSettingsController()..setLanguage(AppLanguage.khmer);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'KhBattambang'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: AgencyStatusBars(agencies: dashboard.agencies),
              ),
            ),
          ),
        ),
      );
      for (final language in [
        AppLanguage.khmer,
        AppLanguage.english,
        AppLanguage.khmer,
      ]) {
        settings.setLanguage(language);
        await tester.pumpAndSettle();
        for (final source in sourceAgencies) {
          final labelFinder = find.byKey(
            ValueKey('agency-${source['agencyId']}-name'),
          );
          final label = tester.widget<Text>(labelFinder);
          final abbreviation =
              (source['agencyKhAbbreviation'] as String?)?.trim() ?? '';
          expect(
            label.data,
            language == AppLanguage.khmer && abbreviation.isNotEmpty
                ? abbreviation
                : source['agencyName'],
          );
          final totalFinder = find.byKey(
            ValueKey('agency-${source['agencyId']}-total'),
          );
          final barFinder = find.byKey(
            ValueKey('agency-${source['agencyId']}-solved'),
          );
          expect(
            tester.getRect(labelFinder).right,
            lessThan(tester.getRect(totalFinder).left),
          );
          expect(
            tester.getRect(totalFinder).right,
            lessThan(tester.getRect(barFinder).left),
          );
        }
        expect(tester.takeException(), isNull);
      }
      expect(find.text('MoC'), findsOneWidget);
      expect(find.text('MoH'), findsOneWidget);
      expect(find.text('MPTC'), findsOneWidget);
      expect(find.text('MoEYS'), findsOneWidget);
      expect(find.text('ក.ស.ក.'), findsOneWidget);
    },
  );

  testWidgets(
    'API Khmer agency abbreviations survive filtering and language changes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await (FontLoader(
        'KhBattambang',
      )..addFont(rootBundle.load('assets/fonts/KhBattambang.ttf'))).load();
      final json =
          jsonDecode(
                File(
                  'test/fixtures/plenary_khmer_agencies.json',
                ).readAsStringSync(),
              )['data']
              as Map<String, dynamic>;
      final dashboard = PswgDashboard.fromJson(json);
      final snapshot = DashboardSnapshot.fromJson(
        json,
        scope: DashboardScope.plenary,
      );
      final sourceAgencies = json['byPrimaryAgency'] as List;
      expect(dashboard.cards['totalIssues'], 179);
      final filtered = dashboard.filtered(
        FilterSelection({
          'local.status': {'SOLVED'},
        }),
      );
      for (final source in sourceAgencies) {
        final id = source['agencyId'];
        for (final agencies in [
          dashboard.agencies,
          snapshot.agencies,
          filtered.agencies,
        ]) {
          final agency = agencies.singleWhere((agency) => agency.id == id);
          expect(agency.name, source['agencyName']);
          expect(agency.khmerName, source['agencyKhName']);
          expect(agency.khmerAbbreviation, source['agencyKhAbbreviation']);
        }
      }
      final settings = AppSettingsController()..setLanguage(AppLanguage.khmer);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'KhBattambang'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: AgencyStatusBars(agencies: filtered.agencies),
              ),
            ),
          ),
        ),
      );
      for (final language in [
        AppLanguage.khmer,
        AppLanguage.english,
        AppLanguage.khmer,
      ]) {
        settings.setLanguage(language);
        await tester.pumpAndSettle();
        for (final source in sourceAgencies) {
          final label = tester.widget<Text>(
            find.byKey(ValueKey('agency-${source['agencyId']}-name')),
          );
          expect(
            label.data,
            source[language == AppLanguage.khmer
                ? 'agencyKhAbbreviation'
                : 'agencyName'],
          );
          expect(
            label.semanticsLabel,
            source[language == AppLanguage.khmer
                ? 'agencyKhName'
                : 'agencyName'],
          );
        }
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('agency-37-solved')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('ក្រុមប្រឹក្សាអភិវឌ្ឍន៍កម្ពុជា ·'),
        findsOneWidget,
      );
      Tooltip.dismissAllToolTips();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'agency totals and segment counts stay visible with hover and tap percentages',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController()
        ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(
            home: Scaffold(
              body: AgencyStatusBars(
                agencies: [
                  WorkingGroupSummary(
                    id: 1,
                    name: 'MAFF',
                    total: 3,
                    solved: 2,
                    inProgress: 1,
                    notAddressed: 0,
                  ),
                  WorkingGroupSummary(
                    id: 2,
                    name: 'MEF',
                    total: 2,
                    solved: 2,
                    inProgress: 0,
                    notAddressed: 0,
                  ),
                  WorkingGroupSummary(
                    id: 3,
                    name: 'MoT',
                    total: 0,
                    solved: 0,
                    inProgress: 0,
                    notAddressed: 0,
                  ),
                  WorkingGroupSummary(
                    id: 4,
                    name: 'Test',
                    total: 1,
                    solved: 0,
                    inProgress: 0,
                    notAddressed: 1,
                  ),
                  WorkingGroupSummary(
                    id: 5,
                    name: 'MEF narrow',
                    total: 51,
                    solved: 50,
                    inProgress: 1,
                    notAddressed: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final solved = find.byKey(const ValueKey('agency-1-solved'));
      final progress = find.byKey(const ValueKey('agency-1-inProgress'));
      expect(
        tester.getSize(solved).width,
        closeTo(tester.getSize(progress).width * 2, 0.01),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('agency-2-solved'))).width,
        closeTo(
          tester.getSize(solved).width + tester.getSize(progress).width,
          0.01,
        ),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('agency-4-notAddressed')))
            .width,
        tester.getSize(find.byKey(const ValueKey('agency-2-solved'))).width,
      );
      expect(find.text('100%'), findsOneWidget);
      expect(tester.getTopLeft(solved).dy, tester.getTopLeft(progress).dy);
      expect(
        tester.getTopLeft(progress).dx,
        greaterThan(tester.getTopLeft(solved).dx),
      );
      expect(find.byKey(const ValueKey('agency-3-solved')), findsNothing);
      expect(find.text('MoT'), findsNothing);
      expect(find.byKey(const ValueKey('agency-3-total')), findsNothing);
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(of: progress, matching: find.byType(ColoredBox)),
            )
            .color,
        const Color(0xFFF5B324),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('(3)'), findsOneWidget);
      expect(find.text('(0)'), findsNothing);
      expect(
        find.descendant(of: solved, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: progress, matching: find.text('1')),
        findsOneWidget,
      );
      final narrow = find.byKey(const ValueKey('agency-5-inProgress'));
      final narrowCount = find.descendant(of: narrow, matching: find.text('1'));
      expect(tester.getSize(narrow).width, 18);
      expect(tester.getSize(narrow).height, 22);
      expect(
        tester.getSize(narrowCount).width,
        lessThan(tester.getSize(narrow).width),
      );
      expect(
        tester.widget<Text>(narrowCount).style!.color,
        const Color(0xFF342600),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('agency-5-solved'))).width +
            tester.getSize(narrow).width,
        closeTo(
          tester.getSize(find.byKey(const ValueKey('agency-2-solved'))).width,
          0.01,
        ),
      );
      final narrowBar = find
          .descendant(of: narrow, matching: find.byType(ColoredBox))
          .first;
      expect(
        tester.getCenter(narrowCount).dy,
        closeTo(tester.getCenter(narrowBar).dy, 0.01),
      );
      expect(
        tester.getCenter(narrow).dy,
        tester.getCenter(find.byKey(const ValueKey('agency-5-solved'))).dy,
      );
      await tester.tap(narrow);
      await tester.pumpAndSettle();
      expect(find.text('MEF narrow · In Progress\n1 (1.96%)'), findsOneWidget);
      Tooltip.dismissAllToolTips();
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(319, 699));
      await mouse.moveTo(tester.getCenter(solved));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('MAFF · Solved\n2 (66.67%)'), findsOneWidget);
      await mouse.moveTo(const Offset(319, 699));
      await tester.pumpAndSettle();
      expect(find.text('MAFF · Solved\n2 (66.67%)'), findsNothing);
      await mouse.removePointer();

      await tester.tap(progress);
      await tester.pumpAndSettle();
      expect(find.text('MAFF · In Progress\n1 (33.33%)'), findsOneWidget);
      Tooltip.dismissAllToolTips();
      await tester.pumpAndSettle();
      settings.setLanguage(AppLanguage.khmer);
      await tester.pumpAndSettle();
      expect(find.text('(៣)'), findsOneWidget);
      expect(
        find.descendant(of: narrow, matching: find.text('១')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: solved, matching: find.text('២')),
        findsOneWidget,
      );
      await tester.tap(solved);
      await tester.pumpAndSettle();
      expect(find.textContaining('២ (៦៦.៦៧%)'), findsOneWidget);
      Tooltip.dismissAllToolTips();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
