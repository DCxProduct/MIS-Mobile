import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import '../../../screens/report/tabs/meeting_summary_tab.dart';
import '../../../screens/report/tabs/report_progress_report_tab.dart';
import '../../../translations/app_localizations.dart';

class LineMinistryReportsScreenView extends StatefulWidget {
  const LineMinistryReportsScreenView({super.key});

  @override
  State<LineMinistryReportsScreenView> createState() =>
      _LineMinistryReportsScreenViewState();
}

class _LineMinistryReportsScreenViewState
    extends State<LineMinistryReportsScreenView> {
  int _selectedTab = 0;

  Set<String> _selectedProgressYears = {};
  Set<String> _selectedSemesters = {};
  Set<String> _selectedProgressStatuses = {};

  Set<String> _selectedSummaryStatuses = {};
  Set<String> _selectedSummaryYears = {};
  Set<String> _selectedSummaryIssues = {};

  Future<void> _openProgressReportFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_LineMinistryProgressReportFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LineMinistryProgressReportFilterSheet(
          selectedYears: _selectedProgressYears,
          selectedSemesters: _selectedSemesters,
          selectedStatuses: _selectedProgressStatuses,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedProgressYears = result.years;
        _selectedSemesters = result.semesters;
        _selectedProgressStatuses = result.statuses;
      });
    }
  }

  Future<void> _openMeetingSummaryFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_LineMinistrySummaryFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LineMinistrySummaryFilterSheet(
          selectedStatuses: _selectedSummaryStatuses,
          selectedYears: _selectedSummaryYears,
          selectedNumberOfIssues: _selectedSummaryIssues,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedSummaryStatuses = result.statuses;
        _selectedSummaryYears = result.years;
        _selectedSummaryIssues = result.numberOfIssues;
      });
    }
  }

  int get _activeFilterCount {
    if (_selectedTab == 0) {
      return _selectedProgressYears.length +
          _selectedSemesters.length +
          _selectedProgressStatuses.length;
    } else {
      return _selectedSummaryStatuses.length +
          _selectedSummaryYears.length +
          _selectedSummaryIssues.length;
    }
  }

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

    return ColoredBox(
      color: contentBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: headerBackground,
            padding: EdgeInsets.fromLTRB(14, topPadding > 0 ? topPadding + 12 : 34, 14, 12),
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
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.activeCount,
    required this.onTap,
  });

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

class _LineMinistryProgressReportFilterResult {
  const _LineMinistryProgressReportFilterResult({
    required this.years,
    required this.semesters,
    required this.statuses,
  });

  final Set<String> years;
  final Set<String> semesters;
  final Set<String> statuses;
}

class _LineMinistryProgressReportFilterSheet extends StatefulWidget {
  const _LineMinistryProgressReportFilterSheet({
    required this.selectedYears,
    required this.selectedSemesters,
    required this.selectedStatuses,
  });

  final Set<String> selectedYears;
  final Set<String> selectedSemesters;
  final Set<String> selectedStatuses;

  @override
  State<_LineMinistryProgressReportFilterSheet> createState() =>
      _LineMinistryProgressReportFilterSheetState();
}

class _LineMinistryProgressReportFilterSheetState
    extends State<_LineMinistryProgressReportFilterSheet> {
  late Set<String> _years;
  late Set<String> _semesters;
  late Set<String> _statuses;

  static const _yearItems = ['2026', '2025', '2024'];
  static const _semesterItems = ['Both', 'S1', 'S2'];
  static const _statusItems = ['Sent', 'Draft'];

  @override
  void initState() {
    super.initState();
    _years = {...widget.selectedYears};
    _semesters = {...widget.selectedSemesters};
    _statuses = {...widget.selectedStatuses};
  }

  void _toggle(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Container(
          color: background,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(22, topInset + 24, 22, 12),
                child: Row(
                  children: [
                    const SizedBox(width: 28),
                    Expanded(
                      child: Text(
                        l10n.text('filters'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 25),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 20,
                  ),
                  children: [
                    Text(
                      l10n.text('year'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: _yearItems.map((item) {
                        return CheckboxListTile(
                          title: Text(item, style: const TextStyle(fontSize: 12)),
                          value: _years.contains(item),
                          onChanged: (_) => _toggle(_years, item),
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _LineMinistryProgressReportFilterResult(
                          years: {..._years},
                          semesters: {..._semesters},
                          statuses: {..._statuses},
                        ),
                      );
                    },
                    child: Text(l10n.text('applyFilters')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineMinistrySummaryFilterResult {
  const _LineMinistrySummaryFilterResult({
    required this.statuses,
    required this.years,
    required this.numberOfIssues,
  });

  final Set<String> statuses;
  final Set<String> years;
  final Set<String> numberOfIssues;
}

class _LineMinistrySummaryFilterSheet extends StatefulWidget {
  const _LineMinistrySummaryFilterSheet({
    required this.selectedStatuses,
    required this.selectedYears,
    required this.selectedNumberOfIssues,
  });

  final Set<String> selectedStatuses;
  final Set<String> selectedYears;
  final Set<String> selectedNumberOfIssues;

  @override
  State<_LineMinistrySummaryFilterSheet> createState() =>
      _LineMinistrySummaryFilterSheetState();
}

class _LineMinistrySummaryFilterSheetState
    extends State<_LineMinistrySummaryFilterSheet> {
  late Set<String> _statuses;
  late Set<String> _years;
  late Set<String> _numberOfIssues;

  static const _statusItems = ['Drafted', 'Submitted', 'Completed'];

  @override
  void initState() {
    super.initState();
    _statuses = {...widget.selectedStatuses};
    _years = {...widget.selectedYears};
    _numberOfIssues = {...widget.selectedNumberOfIssues};
  }

  void _toggle(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Container(
          color: background,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(22, topInset + 24, 22, 12),
                child: Row(
                  children: [
                    const SizedBox(width: 28),
                    Expanded(
                      child: Text(
                        l10n.text('filters'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 25),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 20,
                  ),
                  children: [
                    Text(
                      l10n.text('status'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: _statusItems.map((item) {
                        return CheckboxListTile(
                          title: Text(item, style: const TextStyle(fontSize: 12)),
                          value: _statuses.contains(item),
                          onChanged: (_) => _toggle(_statuses, item),
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _LineMinistrySummaryFilterResult(
                          statuses: {..._statuses},
                          years: {..._years},
                          numberOfIssues: {..._numberOfIssues},
                        ),
                      );
                    },
                    child: Text(l10n.text('applyFilters')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
