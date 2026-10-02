import 'package:flutter/material.dart';

import '../../../../core/widgets/filters/app_filter_sheet.dart';
import '../../../../translations/app_localizations.dart';

/// CDC-specific choices and layouts stay outside the shared filter UI.
List<FilterSection> cdcFilterSections(
  BuildContext context,
  Map<String, List<String>> groups, {
  bool compact = false,
}) {
  final l10n = AppLocalizations.of(context);
  String label(String value) => switch (value) {
    'Solved' => l10n.text('solved'),
    'In Progress' => l10n.text('inProgress'),
    'Not Addressed' => l10n.text('notAddressed'),
    'Both' => l10n.text('both'),
    'Sent' => l10n.text('sent'),
    'Draft' => l10n.text('draft'),
    'Drafted' => l10n.text('drafted'),
    'New Submission' => l10n.text('newSubmission'),
    _ => value,
  };

  return [
    for (final group in groups.entries)
      FilterSection(
        id: group.key,
        title: l10n.text(
          group.key == 'categories' ? 'filterCategory' : group.key,
        ),
        options: [
          for (final value in group.value)
            FilterOption(value: value, label: label(value)),
        ],
        collapsedItemCount: switch (group.key) {
          'primaryAgency' => 10,
          'workingGroup' || 'measureCategory' => 5,
          'dateOfDecision' || 'categories' => 4,
          _ => null,
        },
        columns: switch (group.key) {
          'workingGroup' => 1,
          'plenary' ||
          'dateOfDecision' ||
          'categories' ||
          'measureCategory' => 2,
          'year' => 4,
          'progressReport' => group.value.length == 2 ? 3 : 4,
          'primaryAgency' || 'allPswgs' => 5,
          'plenaryEscalation' => compact ? 4 : 2,
          _ => 3,
        },
        exclusiveValues: group.key == 'progressReport'
            ? const {'Both'}
            : const {},
      ),
  ];
}
