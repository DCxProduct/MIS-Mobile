import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/features/cdc_section/reports/rgc_decision_details.dart';
import 'package:gpsf_app/screens/report/report_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('CDC report navigation and filters at 320px in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController()
        ..setModuleType(AppModuleType.cdcSection)
        ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const Scaffold(body: ReportScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MPWT'), findsNWidgets(2));
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Solved'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('View Details').last);
      await tester.pumpAndSettle();
      expect(find.byType(CdcRgcDecisionOverviewScreen), findsOneWidget);
      expect(find.text('RGC Decision Details'), findsOneWidget);
      expect(find.text('179'), findsOneWidget);
      expect(find.text('Apr 28, 2025'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await tester.tap(find.textContaining('5. Entrust').first);
      await tester.pumpAndSettle();
      expect(find.byType(CdcRgcDecisionIssueScreen), findsOneWidget);
      expect(find.text('Solved'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Link to Verification Source'),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('cdc-rgc-issue-details')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.byType(SelectableText), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solved'));
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Filter (1)'), findsOneWidget);
      expect(find.text('MPWT'), findsOneWidget);
      expect(find.text('Nov 13, 2023'), findsNothing);

      await tester.tap(find.text('Filter (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solved'));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('MPWT'), findsOneWidget);
      expect(find.text('Filter (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Filter (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Plenary'), findsOneWidget);
      expect(find.text('19th G-PSF Plenary'), findsOneWidget);
      final expandWorkingGroup = find.byKey(
        const ValueKey('filter-expand-workingGroup'),
      );
      await tester.ensureVisible(expandWorkingGroup);
      await tester.tap(expandWorkingGroup);
      await tester.pumpAndSettle();
      final agriculture = find.byKey(
        const ValueKey('filter-workingGroup-Agriculture and Agro-Industry'),
      );
      await tester.ensureVisible(agriculture);
      await tester.tap(agriculture);
      final date = find.byKey(
        const ValueKey('filter-dateOfDecision-2024-01-24'),
      );
      await tester.scrollUntilVisible(date, 250);
      expect(find.text('Date of Decision'), findsOneWidget);
      await tester.tap(date);
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Filter (3)'), findsOneWidget);
      expect(find.text('MPWT'), findsNothing);
      expect(find.text('No RGC decisions found.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
