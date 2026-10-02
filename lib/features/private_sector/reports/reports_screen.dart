import '../../../core/app_settings.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../../core/widgets/filters/api_filter_scope.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';
import 'tabs/meeting_summary_tab.dart';
import 'tabs/report_progress_report_tab.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedTab = 0;

  FilterSelection _progressFilters = FilterSelection();

  FilterSelection _summaryFilters = FilterSelection();

  Future<void> _openProgressReportFilterSheet(BuildContext context) async {
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          initial: _progressFilters,
          load: catalogs.progressReports,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _progressFilters = result);
  }

  Future<void> _openMeetingSummaryFilterSheet(BuildContext context) async {
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          initial: _summaryFilters,
          load: catalogs.meetingSummaries,
        ),
      ),
    );
    if (mounted && result != null) setState(() => _summaryFilters = result);
  }

  int get _activeFilterCount =>
      _selectedTab == 0 ? _progressFilters.count : _summaryFilters.count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBackground = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);
    final headerBackground = isDark ? AppColors.darkBackground : Colors.white;

    final title = _selectedTab == 0
        ? l10n.text('progressReport')
        : l10n.text('meetingSummary');

    final topPadding = MediaQuery.of(context).viewPadding.top;

    return ApiFilterScope(
      queries: {
        'progress-reports': _progressFilters.toQuery(),
        'meeting-summaries': _summaryFilters.toQuery(),
      },
      selections: {'meeting-summaries': _summaryFilters},
      child: ColoredBox(
        color: contentBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: headerBackground,
              padding: EdgeInsets.fromLTRB(
                14,
                topPadding > 0 ? topPadding + 12 : 34,
                14,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _FilterButton(
                        activeCount: _activeFilterCount,
                        onTap: () {
                          if (_selectedTab == 0) {
                            _openProgressReportFilterSheet(context);
                          } else {
                            _openMeetingSummaryFilterSheet(context);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ReportTabs(
                    selectedIndex: _selectedTab,
                    onSelected: (index) => setState(() => _selectedTab = index),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
              child: _selectedTab == 0
                  ? const ReportProgressReportTab()
                  : const MeetingSummaryTab(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE3E7EC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).text('filter'),
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent(context),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 7),
            Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.onSurface,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTabs extends StatelessWidget {
  const _ReportTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [l10n.text('progressReport'), l10n.text('meetingSummary')];

    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE8EBF0),
        ),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selectedIndex == index
                      ? AppColors.accent(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: selectedIndex == index
                          ? Colors.white
                          : AppColors.mutedText,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        tabs[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selectedIndex == index
                              ? Colors.white
                              : AppColors.mutedText,
                          fontSize: 12,
                          fontWeight: selectedIndex == index
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
