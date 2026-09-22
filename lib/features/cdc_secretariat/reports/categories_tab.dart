import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class CdcReportCategoriesTab extends StatelessWidget {
  const CdcReportCategoriesTab({super.key});

  static const _items = [
    '1. Adjusting business and investment climate',
    '10. Construction and real estate sector',
    '11. Other issues',
    '2. Easing the burden on compliance',
    '3. Facilitation of businesses under tax authorities',
    '4. Trade facilitation under customs jurisdiction',
    '5. Improving transportation and infrastructure',
    '6. Rehabilitation and development of tourism',
    '7. (A) Agricultural and agro-industrial development',
    '8. (E) Banking and Finance Sector',
    '9. Mining and energy sector',
  ];

  @override
  Widget build(BuildContext context) {
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
          _items.length,
          (index) => _CategoryIssueRow(
            label: _items[index],
            bottomPadding: index == _items.length - 1 ? 0 : 13,
          ),
        ),
      ),
    );
  }
}

class _CategoryIssueRow extends StatelessWidget {
  const _CategoryIssueRow({required this.label, required this.bottomPadding});

  final String label;
  final double bottomPadding;

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
                '3',
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
                Expanded(
                  flex: 75,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF009F5C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 25,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A00),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
