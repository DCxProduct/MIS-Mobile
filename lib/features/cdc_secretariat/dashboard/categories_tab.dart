import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../shared/dashboard/widgets/pswg_live_dashboard.dart';
import '../../shared/dashboard/data/working_group_summary.dart';

class CdcSecretariatCategoriesTab extends StatelessWidget {
  const CdcSecretariatCategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = PswgDataScope.maybeOf(context)?.categories;
    final items =
        rows?.map((row) => row.name).toList() ??
        const [
          'Government',
          'Taxation',
          'Human Resource',
          'Trade',
          'Legislation',
          'Procedure',
          'Market',
          'Policy',
          'Strategy',
        ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
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
          (index) => _CategoryIssueRow(
            label: items[index],
            data: rows?[index],
            bottomPadding: index == items.length - 1 ? 0 : 13,
          ),
        ),
      ),
    );
  }
}

class _CategoryIssueRow extends StatelessWidget {
  const _CategoryIssueRow({
    required this.label,
    required this.bottomPadding,
    this.data,
  });

  final String label;
  final double bottomPadding;
  final WorkingGroupSummary? data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${data?.total ?? 3}',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                if (data == null || data!.solved > 0)
                  Expanded(
                    flex: data?.solved ?? 75,
                    child: Container(height: 6, color: const Color(0xFF009F5C)),
                  ),
                if (data == null || (data!.solved > 0 && data!.inProgress > 0))
                  const SizedBox(width: 4),
                if (data == null || data!.inProgress > 0)
                  Expanded(
                    flex: data?.inProgress ?? 25,
                    child: Container(height: 6, color: const Color(0xFFFF8A00)),
                  ),
                if (data != null && data!.notAddressed > 0)
                  Expanded(
                    flex: data!.notAddressed,
                    child: Container(height: 6, color: const Color(0xFFFF3B30)),
                  ),
                if (data != null && data!.total == 0) const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
