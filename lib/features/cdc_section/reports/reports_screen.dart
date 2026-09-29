import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';
import '../../cdc_secretariat/dashboard/filter_sheet.dart';
import '../../cdc_secretariat/reports/report_filter_sheet.dart';
import 'rgc_decision_details.dart';

class CdcSectionReportsScreenView extends StatefulWidget {
  const CdcSectionReportsScreenView({super.key});

  @override
  State<CdcSectionReportsScreenView> createState() => _ReportsState();
}

class _ReportsState extends State<CdcSectionReportsScreenView> {
  CdcDashboardFilters _filters = CdcDashboardFilters();

  Future<void> _openFilters() async {
    final result = await Navigator.of(context).push<CdcDashboardFilters>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CdcReportFilterSheet(initial: _filters),
      ),
    );
    if (mounted && result != null) setState(() => _filters = result);
  }

  bool _matches(CdcRgcReport report) {
    bool includes(String group, String value) {
      final selected = _filters.values[group];
      return selected == null || selected.isEmpty || selected.contains(value);
    }

    return includes('status', report.status) &&
        includes('primaryAgency', report.agency) &&
        includes('plenary', report.plenary) &&
        includes('workingGroup', report.workingGroup) &&
        includes('measureCategory', report.measureCategory) &&
        includes('dateOfDecision', report.decisionDate);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reports = cdcRgcReports.where(_matches).toList();
    return ColoredBox(
      color: cdcReportBackground(context),
      child: Column(
        children: [
          Container(
            color: AppColors.cardBackground(context),
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.viewPaddingOf(context).top + 20,
              16,
              14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.text('rgcDecision'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _openFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondaryText(context),
                    side: BorderSide(color: AppColors.border(context)),
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${l10n.text('filter')}${_filters.count == 0 ? '' : ' (${_filters.count})'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.filter_list, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('cdc-rgc-reports'),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemCount: reports.isEmpty ? 1 : reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) => reports.isEmpty
                  ? Center(child: Text(l10n.text('noRgcDecisions')))
                  : _ReportCard(report: reports[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final CdcRgcReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cdcReportCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.account_balance_outlined,
                  size: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.agency,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              CdcRgcStatus(status: report.status),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in [
            (l10n.text('meetingDate'), report.meetingDate),
            (l10n.text('categories'), report.category),
            (l10n.text('focalPersonHE'), report.focalPerson),
          ]) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.$1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    row.$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border(context)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, size: 14),
                const SizedBox(width: 5),
                Text(
                  l10n.text('twoLinks'),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CdcRgcDecisionOverviewScreen(report: report),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.isDark(context)
                    ? AppColors.darkPrimaryContainer
                    : const Color(0xFFECF9FF),
                foregroundColor: AppColors.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.text('viewDetails'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.chevron_right, size: 19),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
