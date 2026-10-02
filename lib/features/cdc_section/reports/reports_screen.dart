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
  List<RgcMinistry>? _ministries;
  List<RgcDecision> _decisions = [];
  int? _stakeholderId;
  int _page = 0;
  int _totalPages = 0;
  bool _loading = true;
  bool _loadingMore = false;
  int _loadVersion = 0;
  String? _error;
  late RgcDecisionsRepository _repository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository = AppSettings.of(context).rgcDecisions;
    if (_ministries == null) _loadMinistries();
  }

  Future<void> _loadMinistries() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ministries = await _repository.getMinistries();
      if (!mounted) return;
      setState(() {
        _ministries = ministries;
        _stakeholderId = ministries.isEmpty ? null : ministries.first.id;
        _loading = false;
      });
      if (_stakeholderId != null) await _loadPage(1);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'load';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadPage(int page) async {
    final id = _stakeholderId;
    if (id == null) return;
    final version = page == 1 ? ++_loadVersion : _loadVersion;
    final filters = _filters.toQuery();
    setState(() {
      if (page == 1) {
        _loading = true;
        _decisions = [];
        _page = 0;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });
    try {
      final all = _filters.hasLocalFilters
          ? await _repository.getDecisions(
              filters: {'stakeholderId': '$id', ...filters},
            )
          : null;
      final result = all == null
          ? await _repository.getDecisionsPage(
              stakeholderId: id,
              page: page,
              limit: 20,
              filters: filters,
            )
          : null;
      if (!mounted || id != _stakeholderId || version != _loadVersion) return;
      setState(() {
        _decisions = page == 1
            ? all ?? result!.items
            : [..._decisions, ...result!.items];
        _page = page;
        _totalPages = all != null ? 1 : result!.totalPages;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted && id == _stakeholderId && version == _loadVersion) {
        setState(() {
          _error = 'load';
          _loading = false;
          _loadingMore = false;
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
    await _loadPage(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reports = _decisions
        .where((decision) => _filters.matchesLocal(decision.filterValues))
        .toList();
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
                : _error != null && _decisions.isEmpty
                ? Center(
                    child: TextButton(
                      onPressed: _ministries == null
                          ? _loadMinistries
                          : () => _loadPage(1),
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
                      if (_error != null) {
                        return Center(
                          child: TextButton(
                            onPressed: () => _loadPage(_page + 1),
                            child: Text(l10n.text('retry')),
                          ),
                        );
                      }
                      if (_loadingMore) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_page < _totalPages) {
                        return Center(
                          child: TextButton(
                            onPressed: () => _loadPage(_page + 1),
                            child: const Text('Load more'),
                          ),
                        );
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
  final RgcDecision decision;

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
            (l10n.text('meetingDate'), rgcDate(decision.meetingDate)),
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
                  builder: (_) =>
                      CdcRgcDecisionOverviewScreen(decisionId: decision.id),
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
