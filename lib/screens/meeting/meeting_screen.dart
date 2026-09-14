import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../translations/app_localizations.dart';
import '../report/tabs/meeting_summary_tab.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/meeting_request_tab.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  int _selectedTab = 0;

  // Meeting Request Filter State
  Set<String> _selectedWorkingGroups = {};
  Set<String> _selectedAgencies = {};
  Set<String> _selectedStatuses = {};
  String? _selectedDate;

  // Meeting Summary Filter State
  Set<String> _selectedSummaryStatuses = {};
  Set<String> _selectedSummaryYears = {};
  Set<String> _selectedSummaryIssues = {};

  Future<void> _openMeetingFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_MeetingFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MeetingFilterSheet(
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

    return ColoredBox(
      color: contentBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: headerBackground,
            padding: const EdgeInsets.fromLTRB(14, 34, 14, 12),
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
                0 => const MeetingRequestTab(key: ValueKey('requests')),
                1 => const CalendarTab(key: ValueKey('calendar')),
                _ => const MeetingSummaryTab(key: ValueKey('summary')),
              },
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

class _MeetingFilterResult {
  const _MeetingFilterResult({
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

class _MeetingFilterSheet extends StatefulWidget {
  const _MeetingFilterSheet({
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
  State<_MeetingFilterSheet> createState() => _MeetingFilterSheetState();
}

class _MeetingFilterSheetState extends State<_MeetingFilterSheet> {
  late Set<String> _workingGroups;
  late Set<String> _agencies;
  late Set<String> _statuses;
  late TextEditingController _dateController;
  DateTime? _selectedDateObj;
  bool _showCalendar = false;

  bool _showAllGroups = false;

  static const _workingGroupItems = [
    'Law, Tax, and Governance',
    'Tourism',
    'Construction and Real Estate',
    'Energy and Mineral Resources',
    'Non-Bank Financial Services Other issues',
    'Agriculture and Agro-Industry',
    'Manufacturing and Industry',
  ];

  static const _agencyItems = [
    ('NBC', Color(0xFFC89211)),
    ('MAFF', Color(0xFF1E824C)),
    ('MME', Color(0xFF0072CE)),
    ('MEYS', Color(0xFFD32F2F)),
    ('MoE', Color(0xFF2E7D32)),
    ('MLVT', Color(0xFF1565C0)),
    ('MT', Color(0xFFE65100)),
    ('MH', Color(0xFF6A1B9A)),
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
    _dateController = TextEditingController(text: widget.selectedDate ?? '');
    if (widget.selectedDate != null && widget.selectedDate!.isNotEmpty) {
      _selectedDateObj = DateTime(2026, 8, 7);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
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

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[(month - 1) % 12];
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
                      // Section 1: Working Group
                      Text(
                        l10n.text('workingGroup'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _WorkingGroupList(
                        items: _showAllGroups
                            ? _workingGroupItems
                            : _workingGroupItems.take(5).toList(),
                        selectedItems: _workingGroups,
                        onChanged: (value) => _toggle(_workingGroups, value),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showAllGroups = !_showAllGroups;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _showAllGroups
                                      ? l10n.text('viewLess')
                                      : l10n.text('viewAll'),
                                  style: TextStyle(
                                    color: AppColors.accent(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _showAllGroups
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppColors.accent(context),
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section 2: Government Agency
                      Text(
                        l10n.text('governmentAgency'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AgencyBadgeGrid(
                        agencies: _agencyItems,
                        selectedAgencies: _agencies,
                        onChanged: (agency) => _toggle(_agencies, agency),
                      ),

                      const SizedBox(height: 24),

                      // Section 3: Meeting Status
                      Text(
                        l10n.text('meetingStatus'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _StatusCheckGrid(
                        statuses: _statusItems,
                        selectedStatuses: _statuses,
                        onChanged: (status) => _toggle(_statuses, status),
                      ),

                      const SizedBox(height: 24),

                      // Section 4: Meeting Date
                      Text(
                        l10n.text('meetingDate'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: () {
                          setState(() {
                            _showCalendar = !_showCalendar;
                          });
                        },
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g Mon 7th, August 2026',
                          hintStyle: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                          ),
                          suffixIcon: const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                            color: AppColors.mutedText,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkCard
                              : const Color(0xFFFAFAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFE2E7ED),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFE2E7ED),
                            ),
                          ),
                        ),
                      ),
                      if (_showCalendar)
                        _InlineCalendarPicker(
                          initialDate: _selectedDateObj,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedDateObj = date;
                              _dateController.text =
                                  '${_dayName(date.weekday)} ${date.day}${_daySuffix(date.day)}, ${_monthName(date.month)} ${date.year}';
                              _showCalendar = false;
                            });
                          },
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
                        _MeetingFilterResult(
                          workingGroups: {..._workingGroups},
                          agencies: {..._agencies},
                          statuses: {..._statuses},
                          date: _dateController.text,
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

class _InlineCalendarPicker extends StatefulWidget {
  const _InlineCalendarPicker({
    required this.initialDate,
    required this.onDateSelected,
  });

  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_InlineCalendarPicker> createState() => _InlineCalendarPickerState();
}

class _InlineCalendarPickerState extends State<_InlineCalendarPicker> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime(2026, 8, 7);
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  static const _weekDays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  void _previousMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final monthName = _monthNames[month - 1];

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E7ED),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$monthName $year',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_right,
                color: AppColors.primary,
                size: 20,
              ),
              const Spacer(),
              InkWell(
                onTap: _previousMonth,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.keyboard_arrow_left, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _nextMonth,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.keyboard_arrow_right, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: _weekDays.map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startingWeekday + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < startingWeekday) {
                return const SizedBox.shrink();
              }
              final dayNumber = index - startingWeekday + 1;
              final date = DateTime(year, month, dayNumber);
              final isSelected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent(context),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                widget.onDateSelected(_selectedDate);
              },
              child: Text(
                AppLocalizations.of(context).text('apply'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
                      Text(
                        l10n.text('status'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _StatusCheckGrid(
                        statuses: _statusItems,
                        selectedStatuses: _statuses,
                        onChanged: (status) => _toggle(_statuses, status),
                      ),

                      const SizedBox(height: 24),

                      // Section 2: Year
                      Text(
                        l10n.text('year'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _StatusCheckGrid(
                        statuses: _yearItems,
                        selectedStatuses: _years,
                        onChanged: (year) => _toggle(_years, year),
                      ),

                      const SizedBox(height: 24),

                      // Section 3: Number of Issues
                      Text(
                        l10n.text('numberOfIssues'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _StatusCheckGrid(
                        statuses: _issueNumberItems,
                        selectedStatuses: _numberOfIssues,
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

class _WorkingGroupList extends StatelessWidget {
  const _WorkingGroupList({
    required this.items,
    required this.selectedItems,
    required this.onChanged,
  });

  final List<String> items;
  final Set<String> selectedItems;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final selected = selectedItems.contains(item);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CheckTile(
            label: item,
            selected: selected,
            onTap: () => onChanged(item),
          ),
        );
      }).toList(),
    );
  }
}

class _AgencyBadgeGrid extends StatelessWidget {
  const _AgencyBadgeGrid({
    required this.agencies,
    required this.selectedAgencies,
    required this.onChanged,
  });

  final List<(String, Color)> agencies;
  final Set<String> selectedAgencies;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: agencies.map((agency) {
        final name = agency.$1;
        final color = agency.$2;
        final selected = selectedAgencies.contains(name);

        return Container(
          width: 100,
          height: 38,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : const Color(0xFFDCE2E9),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => onChanged(name),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _CheckTileBox(selected: selected),
                  const SizedBox(width: 5),
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: color,
                    child: Text(
                      name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusCheckGrid extends StatelessWidget {
  const _StatusCheckGrid({
    required this.statuses,
    required this.selectedStatuses,
    required this.onChanged,
  });

  final List<String> statuses;
  final Set<String> selectedStatuses;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: statuses.map((status) {
        final selected = selectedStatuses.contains(status);
        return SizedBox(
          width: 100,
          child: _CheckTile(
            label: status,
            selected: selected,
            onTap: () => onChanged(status),
          ),
        );
      }).toList(),
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
