import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';
import 'meeting_detail_screen.dart';
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
  bool _isCalendarListView = true;

  Set<String> _selectedWorkingGroups = {};
  Set<String> _selectedAgencies = {};
  Set<String> _selectedStatuses = {};
  Set<String> _selectedYears = {};
  Set<String> _selectedNumberOfIssues = {};
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
          selectedYears: _selectedYears,
          selectedNumberOfIssues: _selectedNumberOfIssues,
          selectedDate: _selectedDate,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedWorkingGroups = result.workingGroups;
        _selectedAgencies = result.agencies;
        _selectedStatuses = result.statuses;
        _selectedYears = result.years;
        _selectedNumberOfIssues = result.numberOfIssues;
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
    if (_selectedTab == 0 || _selectedTab == 1) {
      int count = _selectedWorkingGroups.length +
          _selectedAgencies.length +
          _selectedStatuses.length +
          _selectedYears.length +
          _selectedNumberOfIssues.length;
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
      child: Column(
        children: [
          // STICKY APP BAR
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
                    if (_selectedTab == 1) ...[
                      _ViewModeToggle(
                        isListView: _isCalendarListView,
                        onToggle: (isList) =>
                            setState(() => _isCalendarListView = isList),
                      ),
                    ] else ...[
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
          // SCROLLABLE CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: switch (_selectedTab) {
                    0 => const _LineMinistryMeetingRequestTab(
                        key: ValueKey('line_ministry_requests'),
                      ),
                    1 => _LineMinistryMeetingCalendarTab(
                        key: ValueKey('line_ministry_calendar_$_isCalendarListView'),
                        isListView: _isCalendarListView,
                        onOpenFilter: () => _openMeetingFilterSheet(context),
                        activeFilterCount: _activeFilterCount,
                      ),
                    _ => const MeetingSummaryTab(
                        key: ValueKey('line_ministry_summary'),
                      ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.isListView,
    required this.onToggle,
  });

  final bool isListView;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => onToggle(true),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isListView ? AppColors.accent(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.format_list_bulleted_rounded,
                color: isListView ? Colors.white : AppColors.mutedText,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: () => onToggle(false),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: !isListView ? AppColors.accent(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: !isListView ? Colors.white : AppColors.mutedText,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineMinistryMeetingCalendarTab extends StatelessWidget {
  const _LineMinistryMeetingCalendarTab({
    super.key,
    required this.isListView,
    required this.onOpenFilter,
    required this.activeFilterCount,
  });

  final bool isListView;
  final VoidCallback onOpenFilter;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FilterButton(
              activeCount: activeFilterCount,
              onTap: onOpenFilter,
            ),
          ),
        ),
        if (isListView) ...const [
          _LineMinistryCalendarListCard(
            title: 'ប្រជុំពិភាក្សាដោះស្រាយបញ្ហា និងស្វែងរកដំណោះស្រាយរួម',
            group: 'Agriculture and Agro-Industry',
            date: '25 May, 2026',
            totalIssues: '3',
            status: _MeetingStatus.submitted,
            description:
                'ក្នុងគោលបំណងដើម្បីពិភាក្សាអំពីបញ្ហានិងស្វែងរកដំណោះស្រាយរវាងវិស័យរដ្ឋនិងវិស័យឯកជន ដំណាក់កាល ពិភាក្សា និងដំណោះស្រាយរវាងក្រសួង/ស្ថាប័នពាក់ព័ន្ធ និងតំណាងវិស័យឯកជន...',
            attachmentCount: '2 Attachement',
          ),
          _LineMinistryCalendarListCard(
            title: 'ប្រជុំពិភាក្សាដោះស្រាយបញ្ហា និងស្វែងរកដំណោះស្រាយរួម',
            group: 'Agriculture and Agro-Industry',
            date: '25 May, 2026',
            totalIssues: '3',
            status: _MeetingStatus.submitted,
            description:
                'ក្នុងគោលបំណងដើម្បីពិភាក្សាអំពីបញ្ហានិងស្វែងរកដំណោះស្រាយរវាងវិស័យរដ្ឋនិងវិស័យឯកជន ដំណាក់កាល ពិភាក្សា និងដំណោះស្រាយរវាងក្រសួង/ស្ថាប័នពាក់ព័ន្ធ និងតំណាងវិស័យឯកជន...',
            attachmentCount: '2 Attachement',
          ),
          _LineMinistryCalendarListCard(
            title: 'ប្រជុំពិភាក្សាដោះស្រាយបញ្ហា និងស្វែងរកដំណោះស្រាយរួម',
            group: 'Agriculture and Agro-Industry',
            date: '25 May, 2026',
            totalIssues: '3',
            status: _MeetingStatus.submitted,
            description:
                'ក្នុងគោលបំណងដើម្បីពិភាក្សាអំពីបញ្ហានិងស្វែងរកដំណោះស្រាយរវាងវិស័យរដ្ឋនិងវិស័យឯកជន ដំណាក់កាល ពិភាក្សា និងដំណោះស្រាយរវាងក្រសួង/ស្ថាប័នពាក់ព័ន្ធ និងតំណាងវិស័យឯកជន...',
            attachmentCount: '2 Attachement',
          ),
        ] else
          const CalendarTab(),
      ],
    );
  }
}

class _LineMinistryCalendarListCard extends StatelessWidget {
  const _LineMinistryCalendarListCard({
    required this.title,
    required this.group,
    required this.date,
    required this.totalIssues,
    required this.status,
    required this.description,
    required this.attachmentCount,
  });

  final String title;
  final String group;
  final String date;
  final String totalIssues;
  final _MeetingStatus status;
  final String description;
  final String attachmentCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LineMinistryMeetingDetailScreen(title: title),
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
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF216AAA), Color(0xFF1EA45B)],
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
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
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: Color(0xFF4C5563), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    attachmentCount,
                    style: const TextStyle(
                      color: Color(0xFF4C5563),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          title: 'សំណើប្រជុំពិភាក្សាដោះស្រាយបញ្ហាចំនួន ៣',
          group: 'Agriculture and Agro-Industry',
          date: '25 May, 2026',
          totalIssues: '3',
          status: _MeetingStatus.submitted,
          attachmentCount: '2 Attachement',
        ),
        _LineMinistryMeetingCard(
          title: 'សំណើប្រជុំពិភាក្សាដោះស្រាយបញ្ហាចំនួន ៥',
          group: 'Agriculture and Agro-Industry',
          date: '25 May, 2026',
          totalIssues: '5',
          status: _MeetingStatus.submitted,
          attachmentCount: '2 Attachement',
        ),
        _LineMinistryMeetingCard(
          title: 'សំណើប្រជុំពិភាក្សាដោះស្រាយបញ្ហាចំនួន ៧',
          group: 'Agriculture and Agro-Industry',
          date: '25 May, 2026',
          totalIssues: '2',
          status: _MeetingStatus.submitted,
          attachmentCount: '2 Attachement',
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
    this.attachmentCount = '2 Attachement',
  });

  final String title;
  final String group;
  final String date;
  final String totalIssues;
  final _MeetingStatus status;
  final String attachmentCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LineMinistryMeetingDetailScreen(title: title),
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
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF216AAA), Color(0xFF1EA45B)],
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 18,
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: Color(0xFF4C5563), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    attachmentCount,
                    style: const TextStyle(
                      color: Color(0xFF4C5563),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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

String _translateFilterLabel(String item, AppLocalizations l10n) {
  switch (item) {
    case 'Drafted':
      return l10n.text('drafted');
    case 'Submitted':
      return l10n.text('submitted');
    case 'Under Review':
      return l10n.text('underReview');
    case 'Scheduled':
      return l10n.text('scheduled');
    case 'Completed':
      return l10n.text('completed');
    case 'Solved':
      return l10n.text('solved');
    case 'In Progress':
      return l10n.text('inProgress');
    case 'Not Address':
    case 'Not Addressed':
      return l10n.text('notAddressed');
    case 'Sent':
      return l10n.text('sent');
    case 'Draft':
      return l10n.text('draft');
    default:
      return item;
  }
}

class _InlineCheckbox extends StatelessWidget {
  const _InlineCheckbox({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final translatedLabel = _translateFilterLabel(label, l10n);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: checked ? AppColors.accent(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: checked
                      ? AppColors.accent(context)
                      : (isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFCED7E1)),
                  width: 1,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check,
                      size: 11,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              translatedLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
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
    required this.years,
    required this.numberOfIssues,
    this.date,
  });

  final Set<String> workingGroups;
  final Set<String> agencies;
  final Set<String> statuses;
  final Set<String> years;
  final Set<String> numberOfIssues;
  final String? date;
}

class _LineMinistryMeetingFilterSheet extends StatefulWidget {
  const _LineMinistryMeetingFilterSheet({
    required this.selectedWorkingGroups,
    required this.selectedAgencies,
    required this.selectedStatuses,
    required this.selectedYears,
    required this.selectedNumberOfIssues,
    this.selectedDate,
  });

  final Set<String> selectedWorkingGroups;
  final Set<String> selectedAgencies;
  final Set<String> selectedStatuses;
  final Set<String> selectedYears;
  final Set<String> selectedNumberOfIssues;
  final String? selectedDate;

  @override
  State<_LineMinistryMeetingFilterSheet> createState() =>
      _LineMinistryMeetingFilterSheetState();
}

class _LineMinistryMeetingFilterSheetState
    extends State<_LineMinistryMeetingFilterSheet> {
  late Set<String> _statuses;
  late Set<String> _years;
  late Set<String> _numberOfIssues;

  static const _statusRow1 = ['Drafted', 'Submitted', 'Under Review'];
  static const _statusRow2 = ['Scheduled', 'Completed'];
  static const _yearItems = ['2026', '2025', '2024', '2023'];
  static const _issueItems = ['1', '2', '3', '4', '5'];

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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
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
                    // SECTION 1: STATUS
                    Text(
                      l10n.text('status'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: _statusRow1.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _statuses.contains(item),
                          onTap: () => _toggle(_statuses, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: _statusRow2.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _statuses.contains(item),
                          onTap: () => _toggle(_statuses, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: YEAR
                    Text(
                      l10n.text('year'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: _yearItems.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _years.contains(item),
                          onTap: () => _toggle(_years, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: NUMBER OF ISSUES
                    Text(
                      l10n.text('numberOfIssues'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 22,
                      runSpacing: 10,
                      children: _issueItems.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _numberOfIssues.contains(item),
                          onTap: () => _toggle(_numberOfIssues, item),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _LineMinistryMeetingFilterResult(
                          workingGroups: {},
                          agencies: {},
                          statuses: {..._statuses},
                          years: {..._years},
                          numberOfIssues: {..._numberOfIssues},
                        ),
                      );
                    },
                    child: Text(
                      l10n.text('applyFilters'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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

  static const _statusRow1 = ['Drafted', 'Submitted', 'Under Review'];
  static const _statusRow2 = ['Scheduled', 'Completed'];
  static const _yearItems = ['2026', '2025', '2024', '2023'];
  static const _issueItems = ['1', '2', '3', '4', '5'];

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
                        'Filters',
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
                    // SECTION 1: STATUS
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: _statusRow1.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _statuses.contains(item),
                          onTap: () => _toggle(_statuses, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: _statusRow2.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _statuses.contains(item),
                          onTap: () => _toggle(_statuses, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: YEAR
                    const Text(
                      'Year',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: _yearItems.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _years.contains(item),
                          onTap: () => _toggle(_years, item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: NUMBER OF ISSUES
                    const Text(
                      'Number of Issues',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 22,
                      runSpacing: 10,
                      children: _issueItems.map((item) {
                        return _InlineCheckbox(
                          label: item,
                          checked: _numberOfIssues.contains(item),
                          onTap: () => _toggle(_numberOfIssues, item),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
