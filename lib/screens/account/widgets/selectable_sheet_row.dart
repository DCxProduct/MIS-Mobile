import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class SelectableSheetRow extends StatelessWidget {
  const SelectableSheetRow({
    super.key,
    required this.selected,
    required this.onTap,
    this.title,
    this.titleWidget,
    this.subtitle,
  });

  final bool selected;
  final VoidCallback onTap;
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child:
                  titleWidget ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? '',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? AppColors.accent(context)
                  : colors.outlineVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
