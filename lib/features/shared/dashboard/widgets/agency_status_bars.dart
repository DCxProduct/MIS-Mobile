import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';
import '../data/working_group_summary.dart';

/// Status proportions fill each agency row; labels retain API counts.
class AgencyStatusBars extends StatelessWidget {
  const AgencyStatusBars({super.key, required this.agencies});

  final List<WorkingGroupSummary> agencies;
  static const _statuses = [
    ('solved', Color(0xFF0DA365)),
    ('inProgress', Color(0xFFF5B324)),
    ('notAddressed', Color(0xFFFF3B40)),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: agencies.isEmpty
          ? Text(l10n.text('noIssuesFound'))
          : LayoutBuilder(
              builder: (context, constraints) {
                const labelWidth = 54.0;
                final barWidth = constraints.maxWidth - labelWidth;
                return Column(
                  children: [
                    for (final agency in agencies)
                      Row(
                        children: [
                          SizedBox(
                            width: labelWidth,
                            child: Text(
                              agency.name,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          Semantics(
                            label: agency.name,
                            value:
                                '${l10n.text('solved')}: ${l10n.number(agency.solved)}, ${l10n.text('inProgress')}: ${l10n.number(agency.inProgress)}, ${l10n.text('notAddressed')}: ${l10n.number(agency.notAddressed)}',
                            child: Container(
                              width: barWidth,
                              height: 22,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final (index, count) in [
                                      agency.solved,
                                      agency.inProgress,
                                      agency.notAddressed,
                                    ].indexed)
                                      if (count > 0)
                                        SizedBox(
                                          key: ValueKey(
                                            'agency-${agency.id}-${_statuses[index].$1}',
                                          ),
                                          width:
                                              (barWidth - 1) *
                                              count /
                                              (agency.solved +
                                                  agency.inProgress +
                                                  agency.notAddressed),
                                          height: 14,
                                          child: ColoredBox(
                                            color: _statuses[index].$2,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 3,
                                                  ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  l10n.number(count),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
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
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: labelWidth),
                      child: Container(
                        padding: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: colors.outlineVariant),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var tick = 0; tick <= 4; tick++)
                              Text(
                                '${l10n.number(tick * 25)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      children: [
                        for (final status in _statuses)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: status.$2,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l10n.text(status.$1),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
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
