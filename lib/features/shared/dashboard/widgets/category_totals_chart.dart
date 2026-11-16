import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';
import '../data/category_order.dart';
import '../data/working_group_summary.dart';

/// Category totals share one scale, so bar lengths can be compared across rows.
class CategoryTotalsChart extends StatefulWidget {
  const CategoryTotalsChart({super.key, required this.categories});

  final List<WorkingGroupSummary> categories;

  @override
  State<CategoryTotalsChart> createState() => _CategoryTotalsChartState();
}

class _CategoryTotalsChartState extends State<CategoryTotalsChart> {
  static const _previewCount = 16;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories
        .where((category) => category.total > 0)
        .toList();
    final l10n = AppLocalizations.of(context);
    final isDark = AppColors.isDark(context);
    final ordered = sortCategoriesForDashboard(categories);
    // Match the Web scale: the largest total fills the track (105 => 0/35/70/105).
    final axisMaximum = categories.fold<int>(
      1,
      (maximum, category) =>
          category.total > maximum ? category.total : maximum,
    );
    final tickCount = axisMaximum < 3 ? axisMaximum : 3;
    final barColor = isDark ? const Color(0xFF70A9DC) : const Color(0xFF193F68);
    final trackColor = isDark
        ? AppColors.darkElevated
        : const Color(0xFFEBF2F7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: categories.isEmpty
          ? Text(l10n.text('noIssuesFound'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final labelWidth = constraints.maxWidth * 0.40;
                final barWidth = constraints.maxWidth - labelWidth - 12;
                return Column(
                  children: [
                    for (final category
                        in _expanded ? ordered : ordered.take(_previewCount))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: labelWidth,
                              child: Text(
                                l10n.category(
                                  category.displayName(l10n.language),
                                ),
                                style: TextStyle(
                                  color: AppColors.primaryText(context),
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Semantics(
                              label: l10n.category(
                                category.displayName(l10n.language),
                              ),
                              value: l10n.number(category.total),
                              child: _CategoryBar(
                                category: category,
                                width: barWidth,
                                axisMaximum: axisMaximum,
                                barColor: barColor,
                                trackColor: trackColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.only(left: labelWidth + 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var index = 0; index <= tickCount; index++)
                            Text(
                              l10n.number(
                                axisMaximum * index / tickCount,
                                decimalPlaces:
                                    (axisMaximum * index) % tickCount == 0
                                    ? 0
                                    : 1,
                              ),
                              key: ValueKey('category-axis-$index'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedText,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (ordered.length > _previewCount)
                      TextButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        child: Text(
                          l10n.text(
                            _expanded
                                ? 'dashboardShowLess'
                                : 'dashboardShowMore',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: barColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.text('totalIssues'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Give small bars enough colored space to keep their counts readable inside.
class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.width,
    required this.axisMaximum,
    required this.barColor,
    required this.trackColor,
  });

  final WorkingGroupSummary category;
  final double width;
  final int axisMaximum;
  final Color barColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final count = AppLocalizations.of(context).number(category.total);
    final style = DefaultTextStyle.of(context).style.merge(
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.2),
    );
    final measurement = TextPainter(
      text: TextSpan(text: count, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final minimumWidth = (measurement.width + 8).clamp(0.0, width);
    final barWidth = (width * category.total / axisMaximum).clamp(
      minimumWidth,
      width,
    );
    final height = (measurement.height + 4).clamp(20.0, double.infinity);
    measurement.dispose();
    final label = Text(
      count,
      key: ValueKey('category-value-${category.id}'),
      maxLines: 1,
      style: style.copyWith(
        color: AppColors.isDark(context)
            ? AppColors.darkBackground
            : Colors.white,
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: ColoredBox(
          key: ValueKey('category-track-${category.id}'),
          color: trackColor,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: barWidth,
                child: ColoredBox(
                  key: ValueKey('category-bar-${category.id}'),
                  color: barColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: label,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
