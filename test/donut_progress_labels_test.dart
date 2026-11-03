import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/features/cdc_section/dashboard/overall_status_card.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  testWidgets('progress percentages align with their actual arcs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('KhBattambang')
      ..addFont(rootBundle.load('assets/fonts/KhBattambang.ttf'));
    await font.load();
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    const preview = ValueKey('preview');
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'KhBattambang'),
          home: Scaffold(
            body: RepaintBoundary(
              key: preview,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: PlenaryProgressStatusCard(
                  cards: {'midProgress': 2, 'earlyProgress': 1},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ring = tester.getRect(
      find
          .byWidgetPredicate(
            (widget) => widget is CustomPaint && widget.painter != null,
          )
          .first,
    );
    final orange = tester.getRect(find.text('66.67%'));
    final yellow = tester.getRect(find.text('33.33%'));
    expect(orange.right, lessThan(ring.left));
    expect(yellow.left, greaterThan(ring.right));
    expect((orange.center.dy - ring.center.dy).abs(), lessThan(10));
    expect((yellow.center.dy - ring.center.dy).abs(), lessThan(10));
    expect(tester.takeException(), isNull);
  });
}
