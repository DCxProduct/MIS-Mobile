import 'package:flutter/material.dart';
import '../../cdc_secretariat/dashboard/data/filter_sections.dart';
import '../../../core/widgets/filters/app_filter_sheet.dart';

import '../../cdc_secretariat/dashboard/data/filter_options.dart';
import '../../cdc_secretariat/dashboard/filter_sheet.dart';

final cdcWorkingGroupDashboardFilterGroups = <String, List<String>>{
  'workingGroup': cdcDashboardFilterGroups['workingGroup']!,
  'status': cdcDashboardFilterGroups['status']!,
  'primaryAgency': cdcDashboardFilterGroups['primaryAgency']!,
  'year': cdcDashboardFilterGroups['year']!,
  'progressReport': ['S1 2025', 'S2 2025'],
};

class CdcWorkingGroupDashboardFilterSheet extends StatelessWidget {
  const CdcWorkingGroupDashboardFilterSheet({super.key, required this.initial});

  final CdcDashboardFilters initial;

  @override
  Widget build(BuildContext context) => AppFilterSheet(
    initial: initial,
    sections: cdcFilterSections(
      context,
      cdcWorkingGroupDashboardFilterGroups,
      compact: true,
    ),
    compact: true,
  );
}
