import 'package:flutter/material.dart';

import '../../../core/widgets/filters/app_filter_sheet.dart';
import 'data/filter_options.dart';
import 'data/filter_sections.dart';

// Keep existing CDC callers compatible while using the global selection model.
typedef CdcDashboardFilters = FilterSelection;

class CdcDashboardFilterSheet extends StatelessWidget {
  const CdcDashboardFilterSheet({
    super.key,
    required this.initial,
    this.groups,
    this.issueLayout = false,
  });

  final CdcDashboardFilters initial;
  final Map<String, List<String>>? groups;
  final bool issueLayout;

  @override
  Widget build(BuildContext context) => AppFilterSheet(
    initial: initial,
    sections: cdcFilterSections(
      context,
      groups ?? cdcDashboardFilterGroups,
      compact: issueLayout,
    ),
    compact: issueLayout,
  );
}
