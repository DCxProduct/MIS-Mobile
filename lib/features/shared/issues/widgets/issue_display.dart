import 'package:flutter/material.dart';
import '../../../../translations/app_localizations.dart';
import '../data/working_group_issue.dart';

String issueDate(BuildContext context, DateTime? date) => date == null
    ? '—'
    : MaterialLocalizations.of(context).formatMediumDate(date);
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
