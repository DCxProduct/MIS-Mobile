import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';
import '../data/working_group_summary.dart';

/// Category totals share one scale, so bar lengths can be compared across rows.
class CategoryTotalsChart extends StatefulWidget {
  const CategoryTotalsChart({super.key, required this.categories});

  final List<WorkingGroupSummary> categories;

  @override
  State<CategoryTotalsChart> createState() => _CategoryTotalsChartState();
}

class _CategoryTotalsChartState extends State<CategoryTotalsChart> {
  static const _previewCount = 14;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories;
    final l10n = AppLocalizations.of(context);
    final isDark = AppColors.isDark(context);
    final ordered = categories.indexed.toList()
      ..sort((a, b) {
        final byTotal = b.$2.total.compareTo(a.$2.total);
        return byTotal == 0 ? a.$1.compareTo(b.$1) : byTotal;
      });
    final maximum = ordered.isEmpty ? 0 : ordered.first.$2.total;
    // Three equal intervals with rounded integer ticks (e.g. 0, 2, 4, 6).
    var magnitude = 1;
    while (maximum > 30 * magnitude) {
      magnitude *= 10;
    }
    final step = [1, 2, 5, 10]
        .map((value) => value * magnitude)
        .firstWhere((value) => value * 3 >= maximum);
    final axisMaximum = step * 3;
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
                    for (final entry
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
                                  entry.$2.displayName(l10n.language),
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
                                entry.$2.displayName(l10n.language),
                              ),
                              value: l10n.number(entry.$2.total),
                              child: SizedBox(
                                width: barWidth,
                                height: 20,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: ColoredBox(
                                    key: ValueKey(
                                      'category-track-${entry.$2.id}',
                                    ),
                                    color: trackColor,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        key: ValueKey(
                                          'category-bar-${entry.$2.id}',
                                        ),
                                        width:
                                            barWidth *
                                            entry.$2.total /
                                            axisMaximum,
                                        height: 20,
                                        child: ColoredBox(
                                          color: barColor,
                                          child: entry.$2.total == 0
                                              ? null
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      l10n.number(
                                                        entry.$2.total,
                                                      ),
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? AppColors
                                                                  .darkBackground
                                                            : Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
                          for (var index = 0; index <= 3; index++)
                            Text(
                              l10n.number(index * step),
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
