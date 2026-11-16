/// Keeps nonzero counts readable inside a single row. Tooltips should use
/// the original counts for exact percentages, not these display widths.
List<double> statusBarWidths(List<int> counts, double width) {
  final widths = List<double>.filled(counts.length, 0);
  final pending = [
    for (var i = 0; i < counts.length; i++)
      if (counts[i] > 0) i,
  ];
  if (pending.isEmpty) return widths;
  final minimum = (width / pending.length).clamp(0.0, 18.0);
  var remaining = width;
  while (pending.isNotEmpty) {
    final total = pending.fold<int>(0, (sum, i) => sum + counts[i]);
    final small = pending
        .where((i) => remaining * counts[i] / total < minimum)
        .toList();
    if (small.isEmpty) {
      for (final i in pending) {
        widths[i] = remaining * counts[i] / total;
      }
      break;
    }
    for (final i in small) {
      widths[i] = minimum;
      remaining -= minimum;
      pending.remove(i);
    }
  }
  return widths;
}
