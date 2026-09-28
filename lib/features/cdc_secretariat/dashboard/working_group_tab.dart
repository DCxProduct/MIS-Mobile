import '../../shared/dashboard/widgets/working_group_live_tab.dart';
import '../../shared/dashboard/widgets/pswg_live_dashboard.dart';
import '../../shared/dashboard/data/working_group_summary.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class CdcSecretariatWorkingGroupTab extends StatelessWidget {
  const CdcSecretariatWorkingGroupTab({super.key, this.groups});

  final List<WorkingGroupSummary>? groups;

  @override
  Widget build(BuildContext context) {
    final data = groups ?? PswgDataScope.maybeOf(context)?.workingGroups;
    if (data == null) {
      return WorkingGroupLiveTab(
        builder: (groups) => CdcSecretariatWorkingGroupTab(groups: groups),
      );
    }
    final items = data.map((group) => group.name).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE9EDF2),
        ),
      ),
      child: Column(
        children: List.generate(
          items.length,
          (index) => _WorkingGroupRow(
            label: items[index],
            group: data[index],
            showDivider: index != items.length - 1,
          ),
        ),
      ),
    );
  }
}

class _WorkingGroupRow extends StatelessWidget {
  const _WorkingGroupRow({
    required this.label,
    required this.showDivider,
    required this.group,
  });

  final WorkingGroupSummary group;
  final String label;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.9),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MiniStatusBars(group: group),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _MiniStatusBars extends StatelessWidget {
  const _MiniStatusBars({required this.group});

  final WorkingGroupSummary group;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _MiniBar(
            color: const Color(0xFFE68225),
            height: group.total == 0 ? 0 : 18 * group.inProgress / group.total,
          ),
          const SizedBox(width: 4),
          _MiniBar(
            color: const Color(0xFFFF3B30),
            height: group.total == 0
                ? 0
                : 18 * group.notAddressed / group.total,
          ),
          const SizedBox(width: 4),
          _MiniBar(
            color: const Color(0xFF24A36A),
            height: group.total == 0 ? 0 : 18 * group.solved / group.total,
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
