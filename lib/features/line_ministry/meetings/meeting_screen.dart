import '../../../core/app_settings.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../../core/widgets/filters/api_filter_scope.dart';
import '../../private_sector/meetings/meeting_request_detail_screen.dart'
    as request_detail;
import '../../shared/meetings/data/meeting_request.dart';
import '../../shared/meetings/widgets/meeting_requests_list.dart';
import '../../shared/issues/widgets/issue_display.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../shared/meetings/data/calendar_meeting.dart';
import '../../shared/meetings/widgets/meetings_loader.dart';
import 'meeting_detail_screen.dart';
import '../../private_sector/meetings/tabs/calendar_tab.dart';
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
  final _filters = [FilterSelection(), FilterSelection(), FilterSelection()];
  Future<void> _openMeetingFilterSheet(BuildContext context) async {
    final catalogs = AppSettings.of(context).filters;
    final tab = _selectedTab;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          initial: _filters[tab],
          load: switch (tab) {
            0 => () => catalogs.meetingRequests(ministry: true),
            1 => catalogs.meetings,
            _ => catalogs.meetingSummaries,
          },
        ),
      ),
    );
    if (mounted && result != null) setState(() => _filters[tab] = result);
  }

  Future<void> _openMeetingSummaryFilterSheet(BuildContext context) =>
      _openMeetingFilterSheet(context);
  int get _activeFilterCount => _filters[_selectedTab].count;

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

    return ApiFilterScope(
      queries: {
        'meeting-requests': _filters[0].toQuery(),
        'meetings': _filters[1].toQuery(),
        'meeting-summaries': _filters[2].toQuery(),
      },
      selections: {
        'meeting-requests': _filters[0],
        'meetings': _filters[1],
        'meeting-summaries': _filters[2],
      },
      child: ColoredBox(
        color: contentBackground,
        child: Column(
          children: [
            // STICKY APP BAR
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
                        key: ValueKey(
                          'line_ministry_calendar_$_isCalendarListView',
                        ),
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
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.isListView, required this.onToggle});

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
                color: isListView
                    ? AppColors.accent(context)
                    : Colors.transparent,
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
                color: !isListView
                    ? AppColors.accent(context)
                    : Colors.transparent,
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
        if (isListView)
          MeetingsLoader(
            builder: (meetings) => Column(
              children: [
                for (final meeting in meetings)
                  _LineMinistryCalendarListCard(meeting: meeting),
              ],
            ),
          )
        else
          const CalendarTab(),
      ],
    );
  }
}

class _LineMinistryCalendarListCard extends StatelessWidget {
  const _LineMinistryCalendarListCard({required this.meeting});

  final CalendarMeeting meeting;

  static String _date(BuildContext context, DateTime? value) => value == null
      ? '—'
      : MaterialLocalizations.of(context).formatMediumDate(value.toLocal());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                LineMinistryMeetingDetailScreen(title: meeting.details.title),
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
                        meeting.details.title,
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
                        meeting.details.group,
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
                    value: _date(context, meeting.date),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MeetingInfo(
                    icon: Icons.file_copy_outlined,
                    label: AppLocalizations.of(context).text('totalIssues'),
                    value: '${meeting.details.issuesCount}',
                    iconColor: const Color(0xFFB642FF),
                    iconBackground: const Color(0xFFF2DDFF),
                  ),
                ),
                _StatusBadge(status: meeting.details.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              meeting.details.description,
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
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE5E8ED),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: Color(0xFF4C5563), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${meeting.details.attachmentCount} ${AppLocalizations.of(context).text('attachmentsLabel')}',
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
    return MeetingRequestsList(
      itemBuilder: (request) => _LineMinistryMeetingCard(request: request),
    );
  }
}

class _LineMinistryMeetingCard extends StatelessWidget {
  const _LineMinistryMeetingCard({required this.request});
  final MeetingRequest request;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = request.title;
    final group = request.group.isEmpty ? '—' : request.group;
    final date = issueDate(context, request.meetingDate);
    final totalIssues = '${request.issuesCount}';
    final status = request.status;
    final attachmentCount =
        '${request.attachmentCount} ${AppLocalizations.of(context).text('attachmentsLabel')}';
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => request_detail.MeetingRequestDetailScreen(
              title: title,
              request: request,
            ),
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
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE5E8ED),
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

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = switch (status) {
      'DRAFT' || 'DRAFTED' => (
        label: AppLocalizations.of(context).text('drafted'),
        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
        background: isDark ? const Color(0xFF222835) : const Color(0xFFF3F4F6),
        border: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
      ),
      'SUBMITTED' => (
        label: AppLocalizations.of(context).text('submitted'),
        color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0E9384),
        background: isDark ? const Color(0xFF123B3A) : const Color(0xFFE6FFFB),
        border: isDark ? const Color(0xFF0F766E) : const Color(0xFF79D7CD),
      ),
      'COMPLETED' => (
        label: AppLocalizations.of(context).text('completed'),
        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
        background: isDark ? const Color(0xFF123B2A) : const Color(0xFFEAFBF0),
        border: isDark ? const Color(0xFF166534) : const Color(0xFF9BE2B4),
      ),
      'UNDER_REVIEW' => (
        label: AppLocalizations.of(context).text('underReview'),
        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFFF8A00),
        background: isDark ? const Color(0xFF423415) : const Color(0xFFFFF6E8),
        border: isDark ? const Color(0xFF92400E) : const Color(0xFFFFC166),
      ),
      _ => (
        label: status == 'SCHEDULED'
            ? AppLocalizations.of(context).text('scheduled')
            : (status.isEmpty ? '—' : status),
        color: isDark ? const Color(0xFF75BFFF) : const Color(0xFF1675C6),
        background: isDark ? const Color(0xFF142E45) : const Color(0xFFF0F8FF),
        border: isDark ? const Color(0xFF356992) : const Color(0xFFB8DCFA),
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

class _MeetingTabs extends StatelessWidget {
  const _MeetingTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      (icon: Icons.add_box_outlined, label: l10n.text('meetingRequest')),
      (
        icon: Icons.calendar_month_outlined,
        label: l10n.text('meetingCalendar'),
      ),
      (icon: Icons.assignment_outlined, label: l10n.text('meetingSummary')),
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
          children: List.generate(tabs.length, (index) {
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
                        color: isSelected ? Colors.white : AppColors.mutedText,
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
          }),
        ),
      ),
    );
  }
}
