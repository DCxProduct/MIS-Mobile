import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/features/shared/dashboard/widgets/donut_label_layout.dart';

void main() {
  test(
    'percentage anchors follow their actual colored arc as API proportions change',
    () {
      const size = Size(280, 195);
      const origin = Offset(140, 97.5);
      for (final fractions in [
        <double>[.95, .05],
        <double>[.2, .3, .5],
        <double>[1],
      ]) {
        final positions = donutLabelLayout(
          fractions: fractions,
          size: size,
          radius: 84,
          startAngle: -math.pi / 2,
        );
        var start = -math.pi / 2;
        for (var i = 0; i < fractions.length; i++) {
          final middle = start + fractions[i] * math.pi;
          final expected =
              origin + Offset(math.cos(middle), math.sin(middle)) * 84;
          expect((positions[i].anchor - expected).distance, lessThan(.001));
          expect(positions[i].center.dx, inInclusiveRange(36, 244));
          expect(positions[i].center.dy, inInclusiveRange(16, 179));
          start += fractions[i] * 2 * math.pi;
        }
      }
      final smallYellow = donutLabelLayout(
        fractions: [.95, .05],
        size: size,
        radius: 84,
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
        size: const Size(280, 195),
        radius: 84,
        startAngle: -math.pi / 2,
      );
      expect(
        (positions[1].center.dy - positions[2].center.dy).abs(),
        greaterThanOrEqualTo(28),
      );
      expect(
        donutLabelLayout(
          fractions: [],
          size: const Size(280, 195),
          radius: 84,
          startAngle: 0,
        ),
        isEmpty,
      );
    },
  );
}
