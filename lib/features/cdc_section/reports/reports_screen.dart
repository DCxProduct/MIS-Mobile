import 'package:flutter/material.dart';
import '../../shared/widgets/list_screen_header.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_settings.dart';
import '../../../translations/app_localizations.dart';
import '../../shared/meetings/data/rgc_decision.dart';
import '../../shared/meetings/data/rgc_decisions_repository.dart';
import '../../shared/issues/widgets/issue_agency_logo.dart';
import '../../cdc_secretariat/dashboard/filter_sheet.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import 'rgc_decision_details.dart';

class CdcSectionReportsScreenView extends StatefulWidget {
  const CdcSectionReportsScreenView({super.key});
  @override
  State<CdcSectionReportsScreenView> createState() => _ReportsState();
}

class _ReportsState extends State<CdcSectionReportsScreenView> {
  CdcDashboardFilters _filters = CdcDashboardFilters();
  List<RgcDecision> _decisions = [];
  bool _loading = true;
  int _loadVersion = 0;
  String? _error;
  RgcDecisionsRepository? _repository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppSettings.of(context).rgcDecisions;
    if (identical(_repository, repository)) return;
    _repository = repository;
    _loadDecisions();
  }

  Future<void> _loadDecisions() async {
    final version = ++_loadVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Complete pagination before grouping so each ministry/plenary card
      // contains all its decisions, including those on later API pages.
      final decisions = await _repository!.getDecisions(
        includePlenaryDetails: true,
        filters: _filters.toQuery(),
      );
      if (!mounted || version != _loadVersion) return;
      setState(() {
        _decisions = decisions;
        _loading = false;
      });
    } catch (_) {
      if (mounted && version == _loadVersion) {
        setState(() {
          _error = 'load';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openFilters() async {
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(initial: _filters, load: catalogs.rgc),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _filters = result);
    await _loadDecisions();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reports = RgcDecisionGroup.fromDecisions(
      _decisions
          .where((decision) => _filters.matchesLocal(decision.filterValues))
          .toList(),
    );
    return ColoredBox(
      color: AppColors.isDark(context)
          ? AppColors.darkBackground
          : const Color(0xFFF7F7F8),
      child: Column(
        children: [
          ListScreenHeader(
            title: l10n.text('rgcDecision'),
            activeCount: _filters.count,
            onFilter: _openFilters,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: TextButton(
                      onPressed: () => _loadDecisions(),
                      child: Text(l10n.text('retry')),
                    ),
                  )
                : ListView.separated(
                    key: const ValueKey('cdc-rgc-reports'),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                    itemCount: reports.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index < reports.length) {
                        return _ReportCard(decision: reports[index]);
                      }
                      return reports.isEmpty
                          ? Center(child: Text(l10n.text('noRgcDecisions')))
                          : const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.decision});
  final RgcDecisionGroup decision;

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
              SizedBox(
                width: 20,
                height: 20,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: IssueAgencyLogo(path: decision.agencyLogo),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rgcValue(decision.agencyName),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              CdcRgcStatus(status: decision.status),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in [
            if (decision.plenaryName.isNotEmpty)
              (l10n.text('plenary'), decision.plenaryName),
            (l10n.text('numberOfRgcDecision'), '${decision.decisions.length}'),
            (l10n.text('meetingDate'), plenaryDate(decision.meetingDate)),
            (l10n.text('categories'), rgcValue(decision.category)),
            (l10n.text('focalPersonHE'), rgcValue(decision.focalPerson)),
          ]) ...[
            Row(
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
                  '${decision.linkCount} Link',
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
                  builder: (_) => CdcRgcDecisionOverviewScreen(
                    decisionId: decision.decisionIds.first,
                    additionalDecisionIds: decision.decisionIds
                        .skip(1)
                        .toList(),
                  ),
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
