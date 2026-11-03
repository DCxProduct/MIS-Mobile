import 'dart:math' as math;
import 'package:flutter/painting.dart';

const donutLabelSize = Size(64, 24);
const donutOverallLabelSize = Size(76, 24);
const donutLabelGap = 8.0;

/// Reserves a label column on each side without covering the ring.
double donutChartRadius(Size size) => math.min(
  85.0,
  math.min(
    (size.width - 2 * (donutLabelSize.width + donutLabelGap)) / 2,
    size.height / 2 - donutLabelSize.height / 2,
  ),
);

/// Places chips beside their arcs, or above/below for the overall chart.
List<({Offset anchor, Offset center})> donutLabelLayout({
  required List<double> fractions,
  required Size size,
  required double radius,
  required double startAngle,
  bool sideLabels = true,
}) {
  final origin = Offset(size.width / 2, size.height / 2);
  final anchors = <Offset>[];
  final centers = <Offset>[];
  final labelSize = sideLabels ? donutLabelSize : donutOverallLabelSize;
  var angle = startAngle;
  for (final fraction in fractions) {
    final sweep = fraction * math.pi * 2;
    final middle = angle + sweep / 2;
    final direction = Offset(math.cos(middle), math.sin(middle));
    anchors.add(origin + direction * radius);
    final halfWidth = labelSize.width / 2;
    final halfHeight = labelSize.height / 2;
    final point = origin + direction * (radius + 12);
    centers.add(
      sideLabels
          ? Offset(
              origin.dx +
                  (direction.dx < 0 ? -1 : 1) *
                      (radius + donutLabelGap + halfWidth),
              (origin.dy + direction.dy * (radius + donutLabelGap)).clamp(
                halfHeight,
                size.height - halfHeight,
              ),
            )
          : Offset(
              point.dx.clamp(halfWidth, size.width - halfWidth),
              origin.dy +
                  (direction.dy < 0 ? -1 : 1) *
                      (radius + donutLabelGap + halfHeight),
            ),
    );
    angle += sweep;
  }
  // Separate labels along their column or row, preserving arc associations.
  double coordinate(Offset point) => sideLabels ? point.dy : point.dx;
  Offset move(Offset point, double value) =>
      sideLabels ? Offset(point.dx, value) : Offset(value, point.dy);
  final spacing =
      (sideLabels ? labelSize.height : labelSize.width) + donutLabelGap;
  final limit = sideLabels
      ? size.height - labelSize.height / 2
      : size.width - labelSize.width / 2;
  for (final group in [false, true]) {
    final indices = [
      for (var i = 0; i < centers.length; i++)
        if (fractions[i] > 0 &&
            (sideLabels
                    ? centers[i].dx > origin.dx
                    : centers[i].dy < origin.dy) ==
                group)
          i,
    ]..sort((a, b) => coordinate(centers[a]).compareTo(coordinate(centers[b])));
    for (var j = 1; j < indices.length; j++) {
      final previous = centers[indices[j - 1]];
      final current = centers[indices[j]];
      centers[indices[j]] = move(
        current,
        math.max(coordinate(current), coordinate(previous) + spacing),
      );
    }
    if (indices.isNotEmpty) {
      final last = centers[indices.last];
      centers[indices.last] = move(last, math.min(coordinate(last), limit));
      for (var j = indices.length - 2; j >= 0; j--) {
        final current = centers[indices[j]];
        centers[indices[j]] = move(
          current,
          math.min(
            coordinate(current),
            coordinate(centers[indices[j + 1]]) - spacing,
          ),
        );
      }
    }
  }
  return [
    for (var i = 0; i < centers.length; i++)
      (anchor: anchors[i], center: centers[i]),
  ];
}
