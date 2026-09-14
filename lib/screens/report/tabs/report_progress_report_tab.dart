import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';
import '../report_detail_screen.dart';

class ReportProgressReportTab extends StatelessWidget {
  const ReportProgressReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ProgressReportCard(title: 'Semester 2'),
        _ProgressReportCard(title: 'Semester 2'),
        _ProgressReportCard(title: 'Semester 2'),
      ],
    );
  }
}

class _ProgressReportCard extends StatelessWidget {
  const _ProgressReportCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFEDEFF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B1F4A)
                      : const Color(0xFFF2D9FF),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '2026',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFD8B4FE)
                        : const Color(0xFFB642FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _ReportDateRow(label: 'Deadline', value: 'Oct 30, 2025'),
          const SizedBox(height: 9),
          const _ReportDateRow(label: '1st Meeting', value: 'Jun 07, 2025'),
          const SizedBox(height: 9),
          const _ReportDateRow(label: '2nd Deadline', value: 'Jun 07, 2025'),
          const SizedBox(height: 9),
          const _ReportDateRow(label: '2nd Meeting', value: 'Jun 07, 2025'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 35,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReportDetailScreen(title: title),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.accent(context).withValues(alpha: 0.18)
                    : const Color(0xFFEAF7FF),
                foregroundColor: AppColors.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.text('viewDetails')),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDateRow extends StatelessWidget {
  const _ReportDateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
