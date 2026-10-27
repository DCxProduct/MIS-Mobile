import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';
import '../../../shared/dashboard/widgets/pswg_live_dashboard.dart';

class PlenaryCategoriesTab extends StatefulWidget {
  const PlenaryCategoriesTab({super.key});

  @override
  State<PlenaryCategoriesTab> createState() => _PlenaryCategoriesTabState();
}

class _PlenaryCategoriesTabState extends State<PlenaryCategoriesTab> {
  static const _collapsedCount = 16;
  static const _statuses = [
    ('solved', Color(0xFF2D7F33)),
    ('inProgress', Color(0xFFF1B128)),
    ('notAddressed', Color(0xFFDF272E)),
  ];
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context, page: 'dashboard_plenary');
    final rows = PswgDataScope.maybeOf(context)?.categories ?? const [];
    // Scale against every category, including rows hidden by View All.
    final maximum = rows.fold<int>(
      1,
      (max, row) => row.total > max ? row.total : max,
    );
    final visible = _expanded ? rows : rows.take(_collapsedCount);
    final isDark = AppColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: rows.isEmpty
          ? Text(l10n.text('noIssuesFound'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final labelWidth = constraints.maxWidth * 0.40;
                final barWidth = constraints.maxWidth - labelWidth - 18;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final row in visible)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: labelWidth,
                              child: Text(
                                l10n.category(row.displayName(l10n.language)),
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: AppColors.primaryText(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 2,
                              height: 20,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF273142),
                            ),
                            const SizedBox(width: 8),
                            Semantics(
                              label: l10n.category(
                                row.displayName(l10n.language),
                              ),
                              value:
                                  '${l10n.text('solved')}: ${l10n.number(row.solved)}, ${l10n.text('inProgress')}: ${l10n.number(row.inProgress)}, ${l10n.text('notAddressed')}: ${l10n.number(row.notAddressed)}',
                              child: SizedBox(
                                width: barWidth,
                                height: 20,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: ColoredBox(
                                    key: ValueKey(
                                      'plenary-category-track-${row.id}',
                                    ),
                                    color: isDark
                                        ? AppColors.darkElevated
                                        : const Color(0xFFEBF2F7),
                                    child: Row(
                                      children: [
                                        for (final (index, count) in [
                                          row.solved,
                                          row.inProgress,
                                          row.notAddressed,
                                        ].indexed)
                                          if (count > 0)
                                            SizedBox(
                                              key: ValueKey(
                                                'plenary-category-${row.id}-${_statuses[index].$1}',
                                              ),
                                              width: barWidth * count / maximum,
                                              height: 20,
                                              child: ColoredBox(
                                                color: _statuses[index].$2,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      l10n.number(count),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (rows.length > _collapsedCount)
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          child: Text(
                            l10n.text(
                              _expanded
                                  ? 'dashboardShowLess'
                                  : 'dashboardShowMore',
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 10,
                        children: [
                          for (final status in _statuses)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: status.$2,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.text(status.$1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
