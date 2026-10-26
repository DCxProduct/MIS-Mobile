import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';
import '../../../shared/issues/data/issue_progress_report.dart';
import '../../../shared/issues/data/working_group_issue.dart';
import '../../../shared/issues/widgets/issue_display.dart';
import '../issue_progress_report_detail_screen.dart';

class IssueProgressReportTab extends StatelessWidget {
  const IssueProgressReportTab({
    super.key,
    this.issue,
    this.onRefresh,
    this.fallbackIssue,
  });

  final WorkingGroupIssue? issue;
  final WorkingGroupIssue? fallbackIssue;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final reports = issue?.reportsIncluded == true
        ? issue!.progressReports
        : fallbackIssue?.progressReports ??
              issue?.progressReports ??
              const <IssueProgressReport>[];
    if (reports.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Text(
                  AppLocalizations.of(context).text('noIssueProgressData'),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _ProgressReportCard(
        report: reports[index],
        issue: issue!,
        onRefresh: onRefresh,
      ),
    );
  }
}

class _ProgressReportCard extends StatelessWidget {
  const _ProgressReportCard({
    required this.report,
    required this.issue,
    this.onRefresh,
  });

  final IssueProgressReport report;
  final WorkingGroupIssue issue;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context, page: 'issue_report');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            issueProgressReportTitle(context, report),
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _ReportMetaRow(
            label: l10n.text('implementationDate'),
            value: issueDate(context, report.implementationDate),
          ),
          const SizedBox(height: 8),
          _ReportMetaRow(
            label: l10n.text('referenceName'),
            value: report.referenceName.isEmpty ? '—' : report.referenceName,
          ),
          if (report.attachmentPaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border(context)),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link,
                    size: 14,
                    color: AppColors.secondaryText(context),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '${l10n.number(report.attachmentPaths.length)} ${l10n.text('attachmentsLabel')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => IssueProgressReportDetailScreen(
                      title: issue.title,
                      report: report,
                      meetingDocumentPath:
                          issue.meetingRequestDocumentPath ?? '',
                      meetingDocumentName: issue.meetingRequestDocumentName,
                      issueStatus: issue.statusCode.isEmpty
                          ? issue.statusName
                          : issue.statusCode,
                    ),
                  ),
                );
                await onRefresh?.call();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.isDark(context)
                    ? AppColors.accent(context).withValues(alpha: 0.18)
                    : const Color(0xFFECF9FE),
                foregroundColor: AppColors.accent(context),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.text('viewDetails')),
                  const SizedBox(width: 6),
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

class _ReportMetaRow extends StatelessWidget {
  const _ReportMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 4,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 6,
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 12, color: AppColors.primaryText(context)),
        ),
      ),
    ],
  );
}
