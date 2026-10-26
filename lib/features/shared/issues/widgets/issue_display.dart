import 'package:flutter/material.dart';
import '../../../../translations/app_localizations.dart';
import '../data/working_group_issue.dart';
import '../data/issue_progress_report.dart';

String issueProgressReportTitle(
  BuildContext context,
  IssueProgressReport report,
) {
  final l10n = AppLocalizations.of(context, page: 'issue_report');
  if (report.title.isEmpty) return l10n.text('progressReport');
  if (!report.hasGeneratedTitle) return report.title;
  return l10n.number(
    l10n
        .api('issue_matrix.report_tab', fallback: report.title)
        .replaceAll('{semester}', l10n.number(report.semester))
        .replaceAll(
          '{year}',
          report.year == null ? '' : l10n.number(report.year),
        )
        .trim(),
  );
}

String issueDate(BuildContext context, DateTime? date) =>
    issueDateWithYear(context, date);

String issueDateWithYear(BuildContext context, DateTime? date) =>
    AppLocalizations.of(context).date(date);

String issueDateWithTime(BuildContext context, DateTime? date) =>
    AppLocalizations.of(
      context,
    ).dateTime(date, use24Hour: MediaQuery.alwaysUse24HourFormatOf(context));
String issueStatusLabel(BuildContext context, WorkingGroupIssue issue) {
  final l10n = AppLocalizations.of(context);
  final code = issue.statusCode.trim();
  final label = l10n.status(code);
  return code.isEmpty || label == code ? l10n.status(issue.statusName) : label;
}

String meetingRequestStatusLabel(BuildContext context, String status) =>
    AppLocalizations.of(context).status(status);
