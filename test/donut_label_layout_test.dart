import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/donut_label_layout.dart';

void main() {
  test(
    'overall chart keeps its percentage labels above and below the ring',
    () {
      const size = Size(320, 240);
      const radius = 84.0;
      final positions = donutLabelLayout(
        fractions: [.938, .062],
        size: size,
        radius: radius,
        startAngle: -math.pi / 2,
        sideLabels: false,
      );
      final origin = size.center(Offset.zero);
      expect(positions[0].center.dy, 224);
      expect(positions[1].center.dy, 16);
      for (final position in positions) {
        expect((position.center.dx - origin.dx).abs(), lessThan(20));
        final chip = Rect.fromCenter(
          center: position.center,
          width: donutOverallLabelSize.width,
          height: donutOverallLabelSize.height,
        );
        expect(
          chip.overlaps(Rect.fromCircle(center: origin, radius: radius)),
          isFalse,
        );
      }
    },
  );

  test(
    'percentage anchors follow their actual colored arc as API proportions change',
    () {
      const size = Size(280, 240);
      const origin = Offset(140, 120);
      final radius = donutChartRadius(size);
      for (final fractions in [
        <double>[.95, .05],
        <double>[.2, .3, .5],
        <double>[1],
      ]) {
        final positions = donutLabelLayout(
          fractions: fractions,
          size: size,
          radius: radius,
          startAngle: -math.pi / 2,
        );
        var start = -math.pi / 2;
        for (var i = 0; i < fractions.length; i++) {
          final middle = start + fractions[i] * math.pi;
          final expected =
              origin + Offset(math.cos(middle), math.sin(middle)) * radius;
          expect((positions[i].anchor - expected).distance, lessThan(.001));
          expect(positions[i].center.dx, inInclusiveRange(32, 248));
          expect(positions[i].center.dy, inInclusiveRange(12, 228));
          start += fractions[i] * 2 * math.pi;
        }
      }
      final smallYellow = donutLabelLayout(
        fractions: [.95, .05],
        size: size,
        radius: radius,
        startAngle: -math.pi / 2,
      );
      expect(smallYellow[1].center.dy, lessThan(origin.dy));
      expect(smallYellow[0].center.dy, greaterThan(origin.dy));
    },
  );

  test(
    'adjacent small statuses have separate chips and empty data has no labels',
    () {
      final positions = donutLabelLayout(
        fractions: [.98, .01, .01],
        size: const Size(280, 240),
        radius: donutChartRadius(const Size(280, 240)),
        startAngle: -math.pi / 2,
      );
      expect(
        (positions[1].center.dy - positions[2].center.dy).abs(),
        greaterThanOrEqualTo(donutLabelSize.height + donutLabelGap),
      );
      expect(
        donutLabelLayout(
          fractions: [],
          size: const Size(280, 240),
          radius: 84,
          startAngle: 0,
        ),
        isEmpty,
      );
    },
  );

  test('whole percentage chips stay outside the ring and inside the card', () {
    for (final width in [250.0, 280.0, 320.0]) {
      final size = Size(width, 240);
      final origin = size.center(Offset.zero);
      final radius = donutChartRadius(size);
      for (final fractions in [
        <double>[.95, .05],
        <double>[.98, .01, .01],
        <double>[.2, .3, .5],
        <double>[.25, .25, .25, .25],
        <double>[0, 1, 0],
        <double>[1],
      ]) {
        for (final start in [-math.pi / 2, -.4, 1.0]) {
          final positions = donutLabelLayout(
            fractions: fractions,
            size: size,
            radius: radius,
            startAngle: start,
          );
          final chips = [
            for (var i = 0; i < fractions.length; i++)
              if (fractions[i] > 0)
                Rect.fromCenter(
                  center: positions[i].center,
                  width: donutLabelSize.width,
                  height: donutLabelSize.height,
                ),
          ];
          for (var i = 0; i < chips.length; i++) {
            final chip = chips[i];
            expect(chip.left, greaterThanOrEqualTo(0));
            expect(chip.right, lessThanOrEqualTo(width));
            expect(chip.top, greaterThanOrEqualTo(0));
            expect(chip.bottom, lessThanOrEqualTo(size.height));
            final closest = Offset(
              origin.dx.clamp(chip.left, chip.right),
              origin.dy.clamp(chip.top, chip.bottom),
            );
            expect(
              (closest - origin).distance,
              greaterThanOrEqualTo(radius + donutLabelGap - .001),
            );
            for (var j = i + 1; j < chips.length; j++) {
              expect(chip.overlaps(chips[j]), isFalse);
            }
          }
        }
      }
    }
  });

  test(
    'two-thirds progress is labeled on the left and one-third on the right',
    () {
      for (final width in [320.0, 390.0, 600.0]) {
        final size = Size(width, 240);
        final positions = donutLabelLayout(
          fractions: [2 / 3, 1 / 3],
          size: size,
          radius: donutChartRadius(size),
          startAngle: 1,
        );
        final origin = size.center(Offset.zero);
        expect(positions[0].center.dx, lessThan(origin.dx));
        expect(positions[1].center.dx, greaterThan(origin.dx));
        for (final position in positions) {
          expect((position.center.dy - origin.dy).abs(), lessThan(8));
          final labelEdge = position.center.dx < origin.dx
              ? position.center.dx + donutLabelSize.width / 2
              : position.center.dx - donutLabelSize.width / 2;
          expect((labelEdge - position.anchor.dx).abs(), lessThan(10));
        }
      }
    },
  );
}
