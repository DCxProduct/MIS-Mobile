import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../features/shared/meetings/data/progress_report.dart';
import '../../../features/shared/meetings/widgets/progress_reports_loader.dart';
import '../../../translations/app_localizations.dart';
import '../progress_report_detail_loader.dart';

class ReportProgressReportTab extends StatelessWidget {
  const ReportProgressReportTab({
    super.key,
    this.years = const {},
    this.semesters = const {},
    this.statuses = const {},
  });

  final Set<String> years, semesters, statuses;

  @override
  Widget build(BuildContext context) {
    return ProgressReportsLoader(
      builder: (reports) {
        final filtered = reports.where(_matches).toList();
        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(AppLocalizations.of(context).text('noProgressReports')),
          );
        }
        return Column(
          children: [
            for (final report in filtered) _ProgressReportCard(report: report),
          ],
        );
      },
    );
  }

  bool _matches(ProgressReport report) {
    final yearMatch = years.isEmpty || years.contains('${report.year}');
    final semesterMatch =
        semesters.isEmpty ||
        semesters.contains('Both') ||
        semesters.contains(report.semester);
    final normalizedStatuses = statuses.map(_normalize).toSet();
    final statusMatch =
        statuses.isEmpty ||
        normalizedStatuses.contains(_normalize(report.status)) ||
        normalizedStatuses.contains(_normalize(report.reportStatus));
    return yearMatch && semesterMatch && statusMatch;
  }

  static String _normalize(String value) =>
      value.toUpperCase().replaceAll('_', ' ').trim();
}

class _ProgressReportCard extends StatelessWidget {
  const _ProgressReportCard({required this.report});
  final ProgressReport report;

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Text(
                  report.title.isEmpty
                      ? 'Semester ${report.semester}'
                      : report.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _Tag(label: '${report.year}', color: const Color(0xFFB642FF)),
            ],
          ),
          const SizedBox(height: 12),
          _ReportDateRow(
            label: 'Deadline',
            value: _date(context, report.deadline),
          ),
          const SizedBox(height: 9),
          _ReportDateRow(
            label: '1st Meeting',
            value: _date(context, report.firstMeeting),
          ),
          const SizedBox(height: 9),
          _ReportDateRow(
            label: '2nd Deadline',
            value: _date(context, report.secondDeadline),
          ),
          const SizedBox(height: 9),
          _ReportDateRow(
            label: '2nd Meeting',
            value: _date(context, report.secondMeeting),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 35,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProgressReportDetailLoader(id: report.id),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.accent(context).withValues(alpha: .18)
                    : const Color(0xFFEAF7FF),
                foregroundColor: AppColors.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context).text('viewDetails')),
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

  static String _date(BuildContext context, DateTime? value) => value == null
      ? '—'
      : MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _ReportDateRow extends StatelessWidget {
  const _ReportDateRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Row(
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
