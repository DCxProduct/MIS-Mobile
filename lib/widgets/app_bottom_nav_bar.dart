import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../translations/app_localizations.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (
        icon: Icons.grid_view_rounded,
        label: l10n.text('dashboard'),
      ),
      (
        icon: Icons.calendar_month_outlined,
        label: l10n.text('meeting'),
      ),
      (
        icon: Icons.assignment_outlined,
        label: l10n.text('issues'),
      ),
      (
        icon: Icons.folder_outlined,
        label: l10n.text('report'),
      ),
      (
        icon: Icons.person_outline_rounded,
        label: l10n.text('account'),
      ),
    ];

    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        border: Border.all(color: AppColors.border(context)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = selectedIndex == index;
          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  items[index].icon,
                  color: isSelected
                      ? AppColors.accent(context)
                      : AppColors.mutedText,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  items[index].label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.accent(context)
                        : AppColors.mutedText,
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
