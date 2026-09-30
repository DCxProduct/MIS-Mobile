import 'package:flutter/material.dart';
import '../../../../translations/app_localizations.dart';
import '../data/working_group_issue.dart';

String issueDate(BuildContext context, DateTime? date) => date == null
    ? '—'
    : MaterialLocalizations.of(context).formatMediumDate(date);

String issueDateWithYear(BuildContext context, DateTime? date) {
  if (date == null) return '—';
  final l10n = MaterialLocalizations.of(context);
  return '${l10n.formatMediumDate(date)} ${l10n.formatYear(date)}';
}

String issueDateWithTime(BuildContext context, DateTime? date) {
  if (date == null) return '—';
  final localizations = MaterialLocalizations.of(context);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(date),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '${issueDateWithYear(context, date)} | $time';
}

String issueStatusLabel(BuildContext context, WorkingGroupIssue issue) {
  final key = switch (issue.statusCode.toUpperCase()) {
    'SOLVED' => 'solved',
    'IN_PROGRESS' => 'inProgress',
    'NOT_ADDRESSED' => 'notAddressed',
    _ => null,
  };
  return key == null
      ? (issue.statusName.isEmpty ? '—' : issue.statusName)
      : AppLocalizations.of(context).text(key);
}
