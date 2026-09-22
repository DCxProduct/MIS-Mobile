import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/features/cdc_secretariat/dashboard/filter_sheet.dart';

void main() {
  testWidgets('filter drafts cancel safely, apply, reopen and deselect', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    var filters = CdcDashboardFilters();
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    final result = await Navigator.of(context)
                        .push<CdcDashboardFilters>(
                          MaterialPageRoute<CdcDashboardFilters>(
                            fullscreenDialog: true,
                            builder: (_) =>
                                CdcDashboardFilterSheet(initial: filters),
                          ),
                        );
                    if (result != null) filters = result;
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    Future<void> open() async {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    await open();
    final titleRect = tester.getRect(find.text('Filters'));
    final closeRect = tester.getRect(find.byIcon(Icons.close_rounded));
    expect(titleRect.center.dx, closeTo(195, 1));
    expect(closeRect.left, greaterThan(titleRect.right + 40));
    expect(closeRect.right, greaterThan(350));
    await tester.tap(find.byKey(const ValueKey('filter-status-Solved')));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(filters.count, 0);
    await open();
    await tester.tap(find.byKey(const ValueKey('filter-status-Solved')));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(filters.values['status'], {'Solved'});
    await open();
    expect(filters.values['status'], {'Solved'});
    await tester.tap(find.byKey(const ValueKey('filter-status-Solved')));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(filters.count, 0);
  });
}
