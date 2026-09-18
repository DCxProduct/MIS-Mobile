import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import '../../../screens/meeting/meeting_request_detail_screen.dart';
import '../../../screens/meeting/tabs/calendar_tab.dart';
import '../../../screens/report/tabs/meeting_summary_tab.dart';
import '../../../translations/app_localizations.dart';

class LineMinistryMeetingScreenView extends StatefulWidget {
  const LineMinistryMeetingScreenView({super.key});

  @override
  State<LineMinistryMeetingScreenView> createState() =>
      _LineMinistryMeetingScreenViewState();
}

class _LineMinistryMeetingScreenViewState
    extends State<LineMinistryMeetingScreenView> {
  int _selectedTab = 0;

  Set<String> _selectedWorkingGroups = {};
  Set<String> _selectedAgencies = {};
  Set<String> _selectedStatuses = {};
  String? _selectedDate;

  Set<String> _selectedSummaryStatuses = {};
  Set<String> _selectedSummaryYears = {};
  Set<String> _selectedSummaryIssues = {};

  Future<void> _openMeetingFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_LineMinistryMeetingFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LineMinistryMeetingFilterSheet(
          selectedWorkingGroups: _selectedWorkingGroups,
          selectedAgencies: _selectedAgencies,
          selectedStatuses: _selectedStatuses,
          selectedDate: _selectedDate,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedWorkingGroups = result.workingGroups;
        _selectedAgencies = result.agencies;
        _selectedStatuses = result.statuses;
        _selectedDate = result.date;
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
      int count = _selectedWorkingGroups.length +
          _selectedAgencies.length +
          _selectedStatuses.length;
      if (_selectedDate != null && _selectedDate!.isNotEmpty) {
        count++;
      }
      return count;
    } else if (_selectedTab == 2) {
      return _selectedSummaryStatuses.length +
          _selectedSummaryYears.length +
          _selectedSummaryIssues.length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBackground = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);
    final headerBackground = isDark ? AppColors.darkBackground : Colors.white;

    final title = switch (_selectedTab) {
      0 => l10n.text('meetingRequests'),
      1 => l10n.text('meetingCalendar'),
      _ => l10n.text('meetingSummary'),
    };

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
                    if (_selectedTab != 1)
                      _FilterButton(
                        activeCount: _activeFilterCount,
                        onTap: () {
                          if (_selectedTab == 0) {
                            _openMeetingFilterSheet(context);
                          } else if (_selectedTab == 2) {
                            _openMeetingSummaryFilterSheet(context);
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _MeetingTabs(
                  selectedIndex: _selectedTab,
                  onSelected: (index) => setState(() => _selectedTab = index),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: switch (_selectedTab) {
                0 => const _LineMinistryMeetingRequestTab(
                    key: ValueKey('line_ministry_requests'),
                  ),
                1 => const CalendarTab(key: ValueKey('line_ministry_calendar')),
                _ => const MeetingSummaryTab(key: ValueKey('line_ministry_summary')),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LineMinistryMeetingRequestTab extends StatelessWidget {
  const _LineMinistryMeetingRequestTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LineMinistryMeetingCard(
          title: 'កិច្ចប្រជុំពិភាក្សាអន្តរក្រសួងសម្រាប់ដំណោះស្រាយ...',
          group: 'Law, Tax, and Governance',
          date: '12 August, 2026',
          totalIssues: '5',
          status: _MeetingStatus.underReview,
        ),
        _LineMinistryMeetingCard(
          title: 'កិច្ចប្រជុំត្រួតពិនិត្យ និងអនុម័តរបាយការណ៍បច្ចេកទេស...',
          group: 'Agriculture and Agro-Industry',
          date: '9 July, 2026',
          totalIssues: '3',
          status: _MeetingStatus.submitted,
        ),
        _LineMinistryMeetingCard(
          title: 'កិច្ចប្រជុំអន្តរក្រសួងស្ដីពីពន្ធដារ និងគយ...',
          group: 'Law, Tax, and Governance',
          date: '15 June, 2026',
          totalIssues: '4',
          status: _MeetingStatus.completed,
        ),
      ],
    );
  }
}

enum _MeetingStatus { drafted, submitted, completed, underReview }

class _LineMinistryMeetingCard extends StatelessWidget {
  const _LineMinistryMeetingCard({
    required this.title,
    required this.group,
    required this.date,
    required this.totalIssues,
    required this.status,
  });

  final String title;
  final String group;
  final String date;
  final String totalIssues;
  final _MeetingStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MeetingRequestDetailScreen(title: title),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E73BE), Color(0xFF1EA45B)],
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MeetingInfo(
                    icon: Icons.calendar_month_outlined,
                    label: AppLocalizations.of(context).text('meetingDate'),
                    value: date,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MeetingInfo(
                    icon: Icons.file_copy_outlined,
                    label: AppLocalizations.of(context).text('totalIssues'),
                    value: totalIssues,
                    iconColor: const Color(0xFFB642FF),
                    iconBackground: const Color(0xFFF2DDFF),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingInfo extends StatelessWidget {
  const _MeetingInfo({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.primary,
    this.iconBackground = const Color(0xFFDDEEFF),
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDark ? iconColor.withValues(alpha: 0.16) : iconBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? AppColors.secondaryText(context)
                      : AppColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _MeetingStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = switch (status) {
      _MeetingStatus.drafted => (
        label: AppLocalizations.of(context).text('drafted'),
        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
        background: isDark ? const Color(0xFF222835) : const Color(0xFFF3F4F6),
        border: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
      ),
      _MeetingStatus.submitted => (
        label: AppLocalizations.of(context).text('submitted'),
        color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0E9384),
        background: isDark ? const Color(0xFF123B3A) : const Color(0xFFE6FFFB),
        border: isDark ? const Color(0xFF0F766E) : const Color(0xFF79D7CD),
      ),
      _MeetingStatus.completed => (
        label: AppLocalizations.of(context).text('completed'),
        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
        background: isDark ? const Color(0xFF123B2A) : const Color(0xFFEAFBF0),
        border: isDark ? const Color(0xFF166534) : const Color(0xFF9BE2B4),
      ),
      _MeetingStatus.underReview => (
        label: AppLocalizations.of(context).text('underReview'),
        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFFF8A00),
        background: isDark ? const Color(0xFF423415) : const Color(0xFFFFF6E8),
        border: isDark ? const Color(0xFF92400E) : const Color(0xFFFFC166),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: config.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: config.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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

class _MeetingTabs extends StatelessWidget {
  const _MeetingTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      (
        icon: Icons.add_box_outlined,
        label: l10n.text('meetingRequest'),
      ),
      (
        icon: Icons.calendar_month_outlined,
        label: l10n.text('meetingCalendar'),
      ),
      (
        icon: Icons.assignment_outlined,
        label: l10n.text('meetingSummary'),
      ),
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

class _LineMinistryMeetingFilterResult {
  const _LineMinistryMeetingFilterResult({
    required this.workingGroups,
    required this.agencies,
    required this.statuses,
    this.date,
  });

  final Set<String> workingGroups;
  final Set<String> agencies;
  final Set<String> statuses;
  final String? date;
}

class _LineMinistryMeetingFilterSheet extends StatefulWidget {
  const _LineMinistryMeetingFilterSheet({
    required this.selectedWorkingGroups,
    required this.selectedAgencies,
    required this.selectedStatuses,
    this.selectedDate,
  });

  final Set<String> selectedWorkingGroups;
  final Set<String> selectedAgencies;
  final Set<String> selectedStatuses;
  final String? selectedDate;

  @override
  State<_LineMinistryMeetingFilterSheet> createState() =>
      _LineMinistryMeetingFilterSheetState();
}

class _LineMinistryMeetingFilterSheetState
    extends State<_LineMinistryMeetingFilterSheet> {
  late Set<String> _workingGroups;
  late Set<String> _agencies;
  late Set<String> _statuses;

  static const _workingGroupItems = [
    'Law, Tax, and Governance',
    'Tourism',
    'Construction and Real Estate',
    'Energy and Mineral Resources',
    'Agriculture and Agro-Industry',
  ];

  static const _statusItems = [
    'Drafted',
    'Submitted',
    'Under Review',
    'Scheduled',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _workingGroups = {...widget.selectedWorkingGroups};
    _agencies = {...widget.selectedAgencies};
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
    final bottomInset = viewPadding.bottom;

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
                      l10n.text('workingGroup'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: _workingGroupItems.map((item) {
                        return CheckboxListTile(
                          title: Text(item, style: const TextStyle(fontSize: 12)),
                          value: _workingGroups.contains(item),
                          onChanged: (_) => _toggle(_workingGroups, item),
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.text('meetingStatus'),
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
                padding: EdgeInsets.fromLTRB(
                  16,
                  13,
                  16,
                  bottomInset > 0 ? bottomInset + 10 : 12,
                ),
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
                        _LineMinistryMeetingFilterResult(
                          workingGroups: {..._workingGroups},
                          agencies: {..._agencies},
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
  static const _yearItems = ['2026', '2025', '2024'];

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
    final bottomInset = viewPadding.bottom;

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
                padding: EdgeInsets.fromLTRB(
                  16,
                  13,
                  16,
                  bottomInset > 0 ? bottomInset + 10 : 12,
                ),
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
