import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class CdcSecretariatWorkingGroupTab extends StatelessWidget {
  const CdcSecretariatWorkingGroupTab({super.key});

  static const _items = [
    '(A) Agriculture and Agro-industry',
    '(B) Tourism',
    '(D) Law, Tax, and Governance',
    '(C) SMEs, Manufacturing, and Services',
    '(E) Banking and Financial Services',
    '(F) Transportation and Infrastructure',
    '(G) Export Processing and Trade Facilitation',
    '(H) Industrial Relations',
    '(I) Rice and Paddy',
    '(J) Energy and Mineral Resources',
    '(M) Construction and Real Estate',
    '(N) Non-Bank Financial Services Other issues',
  ];

  @override
  Widget build(BuildContext context) {
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
          _items.length,
          (index) => _WorkingGroupRow(
            label: _items[index],
            showDivider: index != _items.length - 1,
          ),
        ),
      ),
    );
  }
}

class _WorkingGroupRow extends StatelessWidget {
  const _WorkingGroupRow({required this.label, required this.showDivider});

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
          const _MiniStatusBars(),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _MiniStatusBars extends StatelessWidget {
  const _MiniStatusBars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _MiniBar(color: const Color(0xFFE68225), height: 9),
          const SizedBox(width: 4),
          _MiniBar(color: const Color(0xFFFF3B30), height: 5),
          const SizedBox(width: 4),
          _MiniBar(color: const Color(0xFF24A36A), height: 16),
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
