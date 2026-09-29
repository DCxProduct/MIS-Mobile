import 'package:flutter/material.dart';

import '../dashboard/data/filter_options.dart';
import '../dashboard/filter_sheet.dart';

final cdcReportFilterGroups = <String, List<String>>{
  'plenary': [
    '19th G-PSF Plenary',
    '20th G-PSF Plenary',
    '21st G-PSF Plenary',
    '22nd G-PSF Plenary',
  ],
  'status': ['Solved', 'In Progress', 'Not Addressed'],
  'workingGroup': [
    'Law, Tax, and Governance',
    'Tourism',
    'Construction and Real Estate',
    'Energy and Mineral Resources',
    'Non-Bank Financial Services Other issues',
    'Agriculture and Agro-Industry',
    'SMEs, Manufacturing and Services',
    'Banking and Financial Services',
    'Transportation and Infrastructure',
    'Export Processing and Trade Facilitation',
    'Industrial Relations',
    'Rice and Paddy',
    'Education',
    'Digital Economy, Society and Telecommunication',
    'Land Administration, Security, Public Order',
  ],
  'primaryAgency': cdcDashboardFilterGroups['primaryAgency']!,
  'measureCategory': [
    '5. Improving transportation and infrastructure',
    '8. Banking and Finance Sector',
    '11. Other issues',
    '7. Agricultural and agro-industrial development',
    '2. Easing the burden on compliance',
    '1. Adjusting business and investment climate',
    '3. Facilitation of businesses under tax authorities',
    '4. Trade facilitation under customs jurisdiction',
    '6. Tourism',
    '9. Mining and energy sector',
    '10. Construction and real estate sector',
  ],
  'dateOfDecision': [
    'Not Specify',
    '2024-01-24',
    '2024-11-23',
    'Not Specified',
    '2024-01-23',
    '2024-10-23',
    '2024-06-24',
    'Not applicable',
  ],
};

class CdcReportFilterSheet extends StatelessWidget {
  const CdcReportFilterSheet({super.key, required this.initial});
  final CdcDashboardFilters initial;

  @override
  Widget build(BuildContext context) => CdcDashboardFilterSheet(
    initial: initial,
    groups: cdcReportFilterGroups,
    reportLayout: true,
  );
}
