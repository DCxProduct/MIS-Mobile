import 'package:flutter/material.dart';

import '../dashboard/filter_sheet.dart';

const cdcIssueFilterGroups = <String, List<String>>{
  'allPswgs': ['CRF', 'ABC', 'GDCE', 'IBC', 'CTF'],
  'year': ['2026', '2025', '2024', '2023'],
  'plenaryEscalation': ['Yes', 'No'],
};

class CdcIssueFilterSheet extends StatelessWidget {
  const CdcIssueFilterSheet({super.key, required this.initial});

  final CdcDashboardFilters initial;

  @override
  Widget build(BuildContext context) => CdcDashboardFilterSheet(
    initial: initial,
    groups: cdcIssueFilterGroups,
    issueLayout: true,
  );
}
