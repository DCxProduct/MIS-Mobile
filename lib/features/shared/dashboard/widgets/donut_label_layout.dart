import 'dart:math' as math;
import 'package:flutter/painting.dart';

/// Anchors each label to its arc midpoint, keeping nearby chips apart.
List<({Offset anchor, Offset center})> donutLabelLayout({
  required List<double> fractions,
  required Size size,
  required double radius,
  required double startAngle,
}) {
  final origin = Offset(size.width / 2, size.height / 2);
  final anchors = <Offset>[];
  final centers = <Offset>[];
  var angle = startAngle;
  for (final fraction in fractions) {
    final sweep = fraction * math.pi * 2;
    final middle = angle + sweep / 2;
    final direction = Offset(math.cos(middle), math.sin(middle));
    anchors.add(origin + direction * radius);
    final point = origin + direction * (radius + 12);
    centers.add(
      Offset(
        point.dx.clamp(36.0, size.width - 36),
        point.dy.clamp(16.0, size.height - 16),
      ),
    );
    angle += sweep;
  }
  // Resolve overlaps on each side without changing which arc owns the label.
  for (final right in [false, true]) {
    final indices = [
      for (var i = 0; i < centers.length; i++)
        if ((centers[i].dx >= origin.dx) == right) i,
    ]..sort((a, b) => centers[a].dy.compareTo(centers[b].dy));
    for (var j = 1; j < indices.length; j++) {
      final previous = centers[indices[j - 1]];
      final current = centers[indices[j]];
      if (current.dy - previous.dy < 28) {
        centers[indices[j]] = Offset(current.dx, previous.dy + 28);
      }
    }
    if (indices.isNotEmpty) {
      final overflow = centers[indices.last].dy - (size.height - 16);
      if (overflow > 0) {
        for (final i in indices) {
          centers[i] = centers[i] - Offset(0, overflow);
        }
      }
    }
  }
  return [
    for (var i = 0; i < centers.length; i++)
      (anchor: anchors[i], center: centers[i]),
  ];
}
