import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import '../../../screens/report/tabs/meeting_summary_tab.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBackground = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);
    final headerBackground = isDark ? AppColors.darkBackground : Colors.white;

    final topPadding = MediaQuery.of(context).viewPadding.top;

    return ColoredBox(
      color: contentBackground,
      child: Column(
        children: [
          // STICKY HEADER
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
                        'Report',
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
          // SCROLLABLE CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
              children: [
                if (_selectedTab == 0) ...const [
                  _ProgressReportCard(
                    title: 'Semester 2',
                    year: '2026',
                    deadline: 'Oct 30, 2025',
                    firstMeeting: 'Jun 07, 2025',
                    secondDeadline: 'Jun 07, 2025',
                    secondMeeting: 'Jun 07, 2025',
                  ),
                  _ProgressReportCard(
                    title: 'Semester 2',
                    year: '2026',
                    deadline: 'Oct 30, 2025',
                    firstMeeting: 'Jun 07, 2025',
                    secondDeadline: 'Jun 07, 2025',
                    secondMeeting: 'Jun 07, 2025',
                  ),
                  _ProgressReportCard(
                    title: 'Semester 2',
                    year: '2026',
                    deadline: 'Oct 30, 2025',
                    firstMeeting: 'Jun 07, 2025',
                    secondDeadline: 'Jun 07, 2025',
                    secondMeeting: 'Jun 07, 2025',
                  ),
                ] else if (_selectedTab == 1) ...const [
                  _ReportDashboardTab(),
                ] else ...const [
                  MeetingSummaryTab(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressReportCard extends StatelessWidget {
  const _ProgressReportCard({
    required this.title,
    required this.year,
    required this.deadline,
    required this.firstMeeting,
    required this.secondDeadline,
    required this.secondMeeting,
  });

  final String title;
  final String year;
  final String deadline;
  final String firstMeeting;
  final String secondDeadline;
  final String secondMeeting;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF0F2F5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B2352)
                      : const Color(0xFFF5E8FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  year,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFD8B4FE)
                        : const Color(0xFF9333EA),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReportRow(label: 'Deadline', value: deadline),
          const SizedBox(height: 8),
          _ReportRow(label: '1st Meeting', value: firstMeeting),
          const SizedBox(height: 8),
          _ReportRow(label: '2nd Deadline', value: secondDeadline),
          const SizedBox(height: 8),
          _ReportRow(label: '2nd Meeting', value: secondMeeting),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.accent(context).withValues(alpha: 0.18)
                    : const Color(0xFFF0F7FF),
                foregroundColor: AppColors.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReportDashboardTab extends StatefulWidget {
  const _ReportDashboardTab();

  @override
  State<_ReportDashboardTab> createState() => _ReportDashboardTabState();
}

class _ReportDashboardTabState extends State<_ReportDashboardTab> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.26,
          children: const [
            _MetricCard(
              label: 'Total Issues',
              value: '179',
              background: Color(0xFFDDEEFF),
              icon: Icons.library_books_outlined,
            ),
            _MetricCard(
              label: 'Solved',
              value: '166/179',
              background: Color(0xFFE5FAEF),
              icon: Icons.fact_check_outlined,
            ),
            _MetricCard(
              label: 'In Progress',
              value: '13/179',
              background: Color(0xFFFFF8DC),
              icon: Icons.add_box_outlined,
            ),
            _MetricCard(
              label: 'Not Addressed',
              value: '0/179',
              background: Color(0xFFFFEEEE),
              icon: Icons.assignment_late_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _TotalPrimaryAgenciesCard(value: '14'),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SubFilterChip(
                label: 'Over All',
                selected: _selectedFilter == 0,
                onTap: () => setState(() => _selectedFilter = 0),
              ),
              const SizedBox(width: 8),
              _SubFilterChip(
                label: 'Agencies',
                selected: _selectedFilter == 1,
                onTap: () => setState(() => _selectedFilter = 1),
              ),
              const SizedBox(width: 8),
              _SubFilterChip(
                label: 'Working Group',
                selected: _selectedFilter == 2,
                onTap: () => setState(() => _selectedFilter = 2),
              ),
              const SizedBox(width: 8),
              _SubFilterChip(
                label: 'Categories',
                selected: _selectedFilter == 3,
                onTap: () => setState(() => _selectedFilter = 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Overall Implementation Status',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 160,
                width: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: 0.9273,
                        strokeWidth: 26,
                        backgroundColor: const Color(0xFFF59E0B),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total Issues',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '179',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.square, color: Color(0xFF10B981), size: 10),
                      SizedBox(width: 6),
                      Text('Solved', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text('(30)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.square, color: Color(0xFFF59E0B), size: 10),
                      SizedBox(width: 6),
                      Text('In Progress', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text('(16)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 160,
                width: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: 0.923,
                        strokeWidth: 26,
                        backgroundColor: const Color(0xFFFDE68A),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFF97316),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'In Progress',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '179',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.square, color: Color(0xFFF97316), size: 10),
                      SizedBox(width: 6),
                      Text('Mid Progress', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text('(30)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.square, color: Color(0xFFFDE68A), size: 10),
                      SizedBox(width: 6),
                      Text('Early Progress', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text('(16)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubFilterChip extends StatelessWidget {
  const _SubFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent(context)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? AppColors.accent(context)
                : (isDark ? AppColors.darkBorder : const Color(0xFFE2E7ED)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark
                    ? AppColors.secondaryText(context)
                    : const Color(0xFF4C5563)),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.background,
    required this.icon,
  });

  final String label;
  final String value;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 10, 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.secondaryText(context)
                        : AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF27364A),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBorder
                  : Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFFE3E8EF) : const Color(0xFF4C5563),
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalPrimaryAgenciesCard extends StatelessWidget {
  const _TotalPrimaryAgenciesCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Primary Agencies',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
              ),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF4C5563),
              size: 20,
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      (icon: Icons.calendar_month_outlined, label: 'Progress Report'),
      (icon: Icons.add_box_outlined, label: 'Dashboard'),
      (icon: Icons.calendar_month_outlined, label: 'Plenaries'),
      (icon: Icons.assignment_outlined, label: 'RGC Decision'),
    ];

    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE8EBF0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            tabs.length,
            (index) {
              final isSelected = selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InkWell(
                  onTap: () => onSelected(index),
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent(context)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tabs[index].icon,
                          color: isSelected
                              ? Colors.white
                              : AppColors.mutedText,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tabs[index].label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.mutedText,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
