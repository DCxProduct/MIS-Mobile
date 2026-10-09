import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';
import '../../shared/issues/data/issue_progress_report.dart';
import '../../shared/issues/widgets/issue_display.dart';
import 'progress_report_detail_screen.dart';
import 'progress_report_data_detail_screen.dart';

class CdcIssueProgressReportCard extends StatelessWidget {
  const CdcIssueProgressReportCard({
    super.key,
    this.report,
    this.issueTitle = '',
    this.issueStatus = '',
    this.meetingDocumentPath = '',
    this.meetingDocumentName = '',
  });

  final IssueProgressReport? report;
  final String issueTitle;
  final String issueStatus;
  final String meetingDocumentPath;
  final String meetingDocumentName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pageBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report == null
                ? 'Report S1 2025'
                : report!.title.isEmpty
                ? l10n.text('progressReport')
                : report!.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _ReportRow(
            label: l10n.text('implementationDate'),
            value: report == null
                ? 'Oct 30, 2025 | 2:00-3:00PM'
                : issueDateWithTime(context, report!.implementationDate),
          ),
          const SizedBox(height: 10),
          _ReportRow(
            label: l10n.text('referenceName'),
            value: report == null
                ? 'របាយការណ៍'
                : report!.referenceName.isEmpty
                ? '—'
                : report!.referenceName,
            maxLines: 1,
          ),
          if (report == null || report!.attachmentPaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${report?.attachmentPaths.length ?? 2} ${l10n.text('attachmentsLabel')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => report == null
                      ? CdcIssueProgressReportDetailScreen(title: issueTitle)
                      : CdcIssueProgressReportDataDetailScreen(
                          report: report!,
                          issueTitle: issueTitle,
                          issueStatus: issueStatus,
                          meetingDocumentPath: meetingDocumentPath,
                          meetingDocumentName: meetingDocumentName,
                        ),
                ),
              ),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.isDark(context)
                    ? AppColors.darkPrimaryContainer
                    : const Color(0xFFEDF8FE),
                foregroundColor: AppColors.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
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

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value, this.maxLines});
  final String label;
  final String value;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 2,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 3,
        child: Text(
          value,
          textAlign: TextAlign.right,
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    ],
  );
}
