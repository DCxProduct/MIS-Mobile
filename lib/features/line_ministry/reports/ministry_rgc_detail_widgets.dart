import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/widgets/pdf_icon.dart';

/// The Ministry web detail uses filled reading panels and outlined references.
class MinistryRgcSection extends StatelessWidget {
  const MinistryRgcSection({
    super.key,
    required this.label,
    required this.child,
    this.outlined = false,
  });

  final String label;
  final Widget child;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: outlined
                ? Colors.transparent
                : AppColors.isDark(context)
                ? const Color(0xFF192233)
                : const Color(0xFFF3F5F8),
            borderRadius: BorderRadius.circular(8),
            border: outlined
                ? Border.all(color: AppColors.border(context))
                : null,
          ),
          child: child,
        ),
      ],
    ),
  );
}

class MinistryRgcMetadata extends StatelessWidget {
  const MinistryRgcMetadata({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
  });
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Icon(icon, size: 18, color: AppColors.secondaryText(context)),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    ],
  );
}

class MinistryRgcReportTabs extends StatelessWidget {
  const MinistryRgcReportTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border(context))),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Semantics(
              selected: index == selected,
              button: true,
              child: InkWell(
                key: ValueKey('ministry-rgc-report-tab-$index'),
                onTap: () => onSelected(index),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: index == selected
                            ? AppColors.accent(context)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: index == selected
                          ? AppColors.accent(context)
                          : AppColors.secondaryText(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// An unavailable file is a visual empty state, never a link to a fake PDF.
class MinistryRgcEmptyAttachment extends StatelessWidget {
  const MinistryRgcEmptyAttachment({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PdfIcon(size: 32),
          const SizedBox(width: 10),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 13))),
        ],
      ),
    ),
  );
}
