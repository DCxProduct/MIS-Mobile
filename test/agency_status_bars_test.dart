import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/features/shared/dashboard/data/working_group_summary.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/agency_status_bars.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  testWidgets(
    'agency status proportions fill rows and retain localized API counts',
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
      expect(find.text('MoT'), findsOneWidget);
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(of: progress, matching: find.byType(ColoredBox)),
            )
            .color,
        const Color(0xFFF5B324),
      );
      expect(tester.takeException(), isNull);
      settings.setLanguage(AppLanguage.khmer);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: solved, matching: find.text('២')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: progress, matching: find.text('១')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
