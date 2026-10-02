import 'package:flutter/material.dart';
import '../dashboard/data/filter_sections.dart';
import '../dashboard/data/filter_options.dart';
import '../../shared/issues/data/working_group_issue.dart';
import '../../../core/widgets/filters/app_filter_sheet.dart';

import '../dashboard/filter_sheet.dart';

final cdcIssueFilterGroups = <String, List<String>>{
  'categories': cdcDashboardFilterGroups['workingGroup']!,
  'status': [
    'Drafted',
    'New Submission',
    'In Progress',
    'Solved',
    'Not Addressed',
  ],
  'allPswgs': ['CRF', 'ABC', 'GDCE', 'IBC', 'CTF'],
  'year': ['2026', '2025', '2024', '2023'],
  'plenaryEscalation': ['Yes', 'No'],
};

class CdcIssueFilterSheet extends StatelessWidget {
  const CdcIssueFilterSheet({super.key, required this.initial});

  final CdcDashboardFilters initial;

  @override
  Widget build(BuildContext context) => AppFilterSheet(
    initial: initial,
    sections: [
      for (final section in cdcFilterSections(
        context,
        cdcIssueFilterGroups,
        compact: true,
      ))
        if (section.id == 'categories')
          FilterSection(
            id: section.id,
            title: section.title,
            options: section.options,
            columns: 2,
            collapsedItemCount: 5,
          )
        else
          section,
    ],
    compact: true,
  );
}

/// Category in this design includes the issue's working-group sector.
bool matchesCdcIssueFilters(
  WorkingGroupIssue issue,
  CdcDashboardFilters filters,
) {
  String normalize(String value) => value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9\u1780-\u17ff]'), '');
  bool includes(String group, Iterable<String> values) {
    final selected = filters.values[group];
    return selected == null ||
        selected.isEmpty ||
        selected.any(
          (value) => values.any(
            (candidate) => normalize(value) == normalize(candidate),
          ),
        );
  }

  final status = switch (issue.statusCode.toUpperCase()) {
    'DRAFT' || 'DRAFTED' || 'SAVED' => 'Drafted',
    'SUBMITTED' || 'NEW_SUBMISSION' => 'New Submission',
    'IN_PROGRESS' => 'In Progress',
    'SOLVED' => 'Solved',
    'NOT_ADDRESSED' => 'Not Addressed',
    _ => issue.statusName,
  };
  final date = issue.createdAt ?? issue.meetingDate;
  return includes('categories', [issue.category, issue.submittedBy]) &&
      includes('status', [status, issue.statusName]) &&
      includes('allPswgs', [issue.agency, issue.submittedBy]) &&
      includes('year', [if (date != null) '${date.year}']) &&
      includes('plenaryEscalation', [
        if (issue.plenaryEscalation != null)
          issue.plenaryEscalation! ? 'Yes' : 'No',
      ]);
}
