import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Progress Report Filter State
  Set<String> _selectedProgressYears = {};
  Set<String> _selectedSemesters = {};
  Set<String> _selectedProgressStatuses = {};

  // Meeting Summary Filter State
  Set<String> _selectedSummaryStatuses = {};
  Set<String> _selectedSummaryYears = {};
  Set<String> _selectedSummaryIssues = {};

  Future<void> _openProgressReportFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_ProgressReportFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ProgressReportFilterSheet(
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
    final result = await showModalBottomSheet<_MeetingSummaryFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MeetingSummaryFilterSheet(
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

class _ProgressReportFilterResult {
  const _ProgressReportFilterResult({
    required this.years,
    required this.semesters,
    required this.statuses,
  });

  final Set<String> years;
  final Set<String> semesters;
  final Set<String> statuses;
}

class _ProgressReportFilterSheet extends StatefulWidget {
  const _ProgressReportFilterSheet({
    required this.selectedYears,
    required this.selectedSemesters,
    required this.selectedStatuses,
  });

  final Set<String> selectedYears;
  final Set<String> selectedSemesters;
  final Set<String> selectedStatuses;

  @override
  State<_ProgressReportFilterSheet> createState() =>
      _ProgressReportFilterSheetState();
}

class _ProgressReportFilterSheetState
    extends State<_ProgressReportFilterSheet> {
  late Set<String> _years;
  late Set<String> _semesters;
  late Set<String> _statuses;

  static const _yearItems = ['2026', '2025', '2024', '2023'];
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
    final borderColor =
        isDark ? AppColors.darkBorder : const Color(0xFFE6E9ED);

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;
    final bottomInset = viewPadding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: background,
          ),
          child: Column(
            children: [
              // ================= FILTER HEADER =================
              Container(
                padding: EdgeInsets.fromLTRB(
                  22,
                  topInset + 24,
                  22,
                  12,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 28),

                    Expanded(
                      child: Text(
                        l10n.text('filters'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(18),
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.close,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ================= FILTER CONTENT =================
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    25,
                    20,
                    25,
                    22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Year
                      _FilterGridSection(
                        title: l10n.text('year'),
                        items: _yearItems,
                        columns: 4,
                        selectedItems: _years,
                        onChanged: (year) => _toggle(_years, year),
                      ),

                      const SizedBox(height: 25),

                      // Section 2: Semester
                      _FilterGridSection(
                        title: l10n.text('semester'),
                        items: _semesterItems,
                        columns: 3,
                        selectedItems: _semesters,
                        onChanged: (sem) => _toggle(_semesters, sem),
                      ),

                      const SizedBox(height: 25),

                      // Section 3: Status
                      _FilterGridSection(
                        title: l10n.text('status'),
                        items: _statusItems,
                        columns: 3,
                        selectedItems: _statuses,
                        onChanged: (status) => _toggle(_statuses, status),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= APPLY BUTTON =================
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  13,
                  16,
                  bottomInset > 0 ? bottomInset + 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: background,
                  border: Border(
                    top: BorderSide(
                      color: borderColor,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _ProgressReportFilterResult(
                          years: {..._years},
                          semesters: {..._semesters},
                          statuses: {..._statuses},
                        ),
                      );
                    },
                    child: Text(
                      l10n.text('applyFilters'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

class _MeetingSummaryFilterResult {
  const _MeetingSummaryFilterResult({
    required this.statuses,
    required this.years,
    required this.numberOfIssues,
  });

  final Set<String> statuses;
  final Set<String> years;
  final Set<String> numberOfIssues;
}

class _MeetingSummaryFilterSheet extends StatefulWidget {
  const _MeetingSummaryFilterSheet({
    required this.selectedStatuses,
    required this.selectedYears,
    required this.selectedNumberOfIssues,
  });

  final Set<String> selectedStatuses;
  final Set<String> selectedYears;
  final Set<String> selectedNumberOfIssues;

  @override
  State<_MeetingSummaryFilterSheet> createState() =>
      _MeetingSummaryFilterSheetState();
}

class _MeetingSummaryFilterSheetState
    extends State<_MeetingSummaryFilterSheet> {
  late Set<String> _statuses;
  late Set<String> _years;
  late Set<String> _numberOfIssues;

  static const _statusItems = [
    'Drafted',
    'Submitted',
    'Under Review',
    'Scheduled',
    'Completed',
  ];

  static const _yearItems = [
    '2026',
    '2025',
    '2024',
    '2023',
  ];

  static const _issueNumberItems = [
    '1',
    '2',
    '3',
    '4',
    '5',
  ];

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
    final borderColor =
        isDark ? AppColors.darkBorder : const Color(0xFFE6E9ED);

    final viewPadding = MediaQuery.of(context).viewPadding;
    final topInset = viewPadding.top > 48.0 ? viewPadding.top : 48.0;
    final bottomInset = viewPadding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: background,
          ),
          child: Column(
            children: [
              // ================= FILTER HEADER =================
              Container(
                padding: EdgeInsets.fromLTRB(
                  22,
                  topInset + 24,
                  22,
                  12,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 28),

                    Expanded(
                      child: Text(
                        l10n.text('filters'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(18),
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.close,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ================= FILTER CONTENT =================
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    25,
                    20,
                    25,
                    22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Status
                      _FilterGridSection(
                        title: l10n.text('status'),
                        items: _statusItems,
                        columns: 3,
                        selectedItems: _statuses,
                        onChanged: (status) => _toggle(_statuses, status),
                      ),

                      const SizedBox(height: 25),

                      // Section 2: Year
                      _FilterGridSection(
                        title: l10n.text('year'),
                        items: _yearItems,
                        columns: 4,
                        selectedItems: _years,
                        onChanged: (year) => _toggle(_years, year),
                      ),

                      const SizedBox(height: 25),

                      // Section 3: Number of Issues
                      _FilterGridSection(
                        title: l10n.text('numberOfIssues'),
                        items: _issueNumberItems,
                        columns: 5,
                        selectedItems: _numberOfIssues,
                        onChanged: (value) => _toggle(_numberOfIssues, value),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= APPLY BUTTON =================
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  13,
                  16,
                  bottomInset > 0 ? bottomInset + 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: background,
                  border: Border(
                    top: BorderSide(
                      color: borderColor,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _MeetingSummaryFilterResult(
                          statuses: {..._statuses},
                          years: {..._years},
                          numberOfIssues: {..._numberOfIssues},
                        ),
                      );
                    },
                    child: Text(
                      l10n.text('applyFilters'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

class _FilterGridSection extends StatelessWidget {
  const _FilterGridSection({
    required this.title,
    required this.items,
    required this.columns,
    required this.selectedItems,
    required this.onChanged,
  });

  final String title;
  final List<String> items;
  final int columns;
  final Set<String> selectedItems;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _FilterGrid(
          items: items,
          columns: columns,
          selectedItems: selectedItems,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FilterGrid extends StatelessWidget {
  const _FilterGrid({
    required this.items,
    required this.columns,
    required this.selectedItems,
    required this.onChanged,
  });

  final List<String> items;
  final int columns;
  final Set<String> selectedItems;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const horizontalGap = 8.0;
    const verticalGap = 15.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - horizontalGap * (columns - 1)) / columns;

        return Wrap(
          spacing: horizontalGap,
          runSpacing: verticalGap,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _CheckTile(
                  label: item,
                  selected: selectedItems.contains(item),
                  onTap: () => onChanged(item),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CheckTileBox(selected: selected),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _localizeLabel(context, label),
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _localizeLabel(BuildContext context, String text) {
  final l10n = AppLocalizations.of(context);
  return switch (text) {
    'Drafted' => l10n.text('drafted'),
    'Submitted' => l10n.text('submitted'),
    'Under Review' => l10n.text('underReview'),
    'Scheduled' => l10n.text('scheduled'),
    'Completed' => l10n.text('completed'),
    'Solved' => l10n.text('solved'),
    'In Progress' => l10n.text('inProgress'),
    'Not Address' || 'Not Addressed' => l10n.text('notAddressed'),
    'Both' => l10n.text('both'),
    'Sent' => l10n.text('sent'),
    'Draft' => l10n.text('draft'),
    'View All' => l10n.text('viewAll'),
    'View Less' => l10n.text('viewLess'),
    _ => text,
  };
}

class _CheckTileBox extends StatelessWidget {
  const _CheckTileBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: selected ? AppColors.accent(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected
              ? AppColors.accent(context)
              : (isDark ? AppColors.darkBorder : const Color(0xFFCED7E1)),
          width: 1,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check,
              size: 11,
              color: Colors.white,
            )
          : null,
    );
  }
}
