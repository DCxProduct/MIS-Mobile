import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';

class CdcOverallStatusCard extends StatelessWidget {
  const CdcOverallStatusCard({
    super.key,
    this.cards,
    required this.workingGroup,
  });

  final Map<String, int?>? cards;
  final bool workingGroup;

  @override
  Widget build(BuildContext context) {
    if (!workingGroup) return CdcPlenaryStatusCards(cards: cards);
    final l10n = AppLocalizations.of(context);
    final total = cards?['totalIssues'] ?? (workingGroup ? 56 : 179);
    final counts = [
      cards?['solved'] ?? (workingGroup ? 30 : 166),
      cards?['inProgress'] ?? (workingGroup ? 16 : 13),
      cards?['notAddressed'] ?? (workingGroup ? 10 : 0),
    ];
    const colors = [Color(0xFF009F59), Color(0xFFE8A51F), Color(0xFFF44336)];
    final shares = counts
        .map((count) => total == 0 ? 0.0 : count / total)
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = ['totalIssues', 'solved', 'inProgress', 'notAddressed'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.text('overallStatus'), style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEEF0F4),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 210,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Semantics(
                        label: '${l10n.text('totalIssues')}: $total',
                        child: CustomPaint(
                          size: const Size(170, 170),
                          painter: _StatusRing(shares, colors),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.text('totalIssues'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.mutedText,
                            ),
                          ),
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (shares[1] > 0)
                        Positioned(
                          top: 8,
                          right: 38,
                          child: _Badge(share: shares[1], color: colors[1]),
                        ),
                      if (shares[2] > 0)
                        Positioned(
                          left: -45,
                          top: 82,
                          child: _Badge(share: shares[2], color: colors[2]),
                        ),
                      if (shares[0] > 0)
                        Positioned(
                          right: 4,
                          bottom: 23,
                          child: _Badge(share: shares[0], color: colors[0]),
                        ),
                    ],
                  ),
                ),
              ),
              for (final index in [0, 1, 2, 3])
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? const Color(0xFF1D66AD)
                              : colors[index - 1],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.text(labels[index]),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                      Text(
                        '(${index == 0 ? total : counts[index - 1]})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.share, required this.color});
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : Colors.white,
      borderRadius: BorderRadius.circular(5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .12),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '${(share * 100).toStringAsFixed(2)}%',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    ),
  );
}

class _StatusRing extends CustomPainter {
  _StatusRing(this.shares, this.colors, {this.startAngle = -.4});
  final List<double> shares;
  final List<Color> colors;
  final double startAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - 30) / 2,
    );
    // Solved occupies the lower/right arc, with progress above and unaddressed left.
    var angle = startAngle;
    for (final i in [0, 2, 1]) {
      final sweep = shares[i] * 2 * math.pi;
      if (sweep <= 0) continue;
      canvas.drawArc(
        rect,
        angle + .012,
        math.max(0, sweep - .024),
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 30,
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusRing oldDelegate) =>
      oldDelegate.shares.toString() != shares.toString() ||
      oldDelegate.colors.toString() != colors.toString() ||
      oldDelegate.startAngle != startAngle;
}

class CdcPlenaryStatusCards extends StatelessWidget {
  const CdcPlenaryStatusCards({super.key, this.cards});
  final Map<String, int?>? cards;

  @override
  Widget build(BuildContext context) {
    final total = cards?['totalIssues'] ?? 179;
    final solved = cards?['solved'] ?? 166;
    final inProgress = cards?['inProgress'] ?? 13;
    final mid = cards == null ? 12 : cards!['midProgress'];
    final early = cards == null ? 1 : cards!['earlyProgress'];
    final progressTotal = (mid ?? 0) + (early ?? 0);
    return Column(
      children: [
        _PlenaryRingCard(
          centerKey: 'totalIssues',
          value: total,
          labels: const ['solved', 'inProgress'],
          counts: [solved, inProgress],
          shares: cards == null
              ? [.9273, .0727]
              : [
                  total == 0 ? 0 : solved / total,
                  total == 0 ? 0 : inProgress / total,
                ],
          colors: const [Color(0xFF009F59), Color(0xFFFFB21C)],
        ),
        const SizedBox(height: 16),
        _PlenaryRingCard(
          centerKey: 'inProgress',
          value: inProgress,
          labels: const ['midProgress', 'earlyProgress'],
          counts: [mid, early],
          shares: [
            progressTotal == 0 ? 0 : (mid ?? 0) / progressTotal,
            progressTotal == 0 ? 0 : (early ?? 0) / progressTotal,
          ],
          colors: const [Color(0xFFF9A15D), Color(0xFFF5DBA9)],
        ),
      ],
    );
  }
}

class _PlenaryRingCard extends StatelessWidget {
  const _PlenaryRingCard({
    required this.centerKey,
    required this.value,
    required this.labels,
    required this.counts,
    required this.shares,
    required this.colors,
  });
  final String centerKey;
  final int value;
  final List<String> labels;
  final List<int?> counts;
  final List<double> shares;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.text('overallStatus'), style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEEF0F4),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 185,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: const Size(170, 170),
                      painter: _StatusRing(
                        shares.any((share) => share > 0)
                            ? [shares[0], shares[1], 0]
                            : [1, 0, 0],
                        shares.any((share) => share > 0)
                            ? [colors[0], colors[1], Colors.transparent]
                            : [
                                const Color(0xFFE5E8ED),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                        startAngle: 1.0,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.text(centerKey),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.mutedText,
                          ),
                        ),
                        Text(
                          '$value',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (shares[0] > 0)
                      Positioned(
                        left: 28,
                        top: 36,
                        child: _Badge(share: shares[0], color: colors[0]),
                      ),
                    if (shares[1] > 0)
                      Positioned(
                        right: 45,
                        bottom: 0,
                        child: _Badge(share: shares[1], color: colors[1]),
                      ),
                  ],
                ),
              ),
              for (final index in [0, 1])
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: colors[index],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.text(labels[index]),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                      Text(
                        counts[index] == null ? '—' : '(${counts[index]})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
