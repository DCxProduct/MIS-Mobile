import '../../../core/widgets/filters/app_filter_button.dart';
import '../../../core/app_settings.dart';
import '../../../core/config/module_config.dart';
import '../../cdc_secretariat/meetings/meeting_request_tab.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../../core/widgets/filters/api_filter_scope.dart';

import '../../../core/app_colors.dart';
import '../../../screens/report/tabs/meeting_summary_tab.dart';
import '../../../translations/app_localizations.dart';
import 'tabs/calendar_tab.dart';
import '../../shared/meetings/widgets/calendar_date_filter_button.dart';
import 'tabs/meeting_request_tab.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  int _selectedTab = 0;
  DateTime? _calendarDate;
  Set<String> _calendarMonths = {};
  bool _showCalendarMonthResults = false;

  final _filters = [FilterSelection(), FilterSelection(), FilterSelection()];
  Future<void> _openMeetingFilterSheet(BuildContext context) async {
    final catalogs = AppSettings.of(context).filters;
    final tab = _selectedTab;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          translationPage: tab == 0 ? 'meeting_requests' : 'meeting_summary',
          initial: _filters[tab],
          load: tab == 0
              ? () => catalogs.meetingRequests()
              : catalogs.meetingSummaries,
        ),
      ),
    );
    if (mounted && result != null) setState(() => _filters[tab] = result);
  }

  Future<void> _openMeetingSummaryFilterSheet(BuildContext context) =>
      _openMeetingFilterSheet(context);
  int get _activeFilterCount => _filters[_selectedTab].count;

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: const [
      'meeting_requests',
      'meeting_calendar',
      'meeting_summary',
    ][_selectedTab],
    child: Builder(builder: _buildContent),
  );

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBackground = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);
    final headerBackground = isDark ? AppColors.darkBackground : Colors.white;

    final title = switch (_selectedTab) {
      0 => l10n.text(
        AppSettings.of(context).moduleType == AppModuleType.cdcSecretariat
            ? 'meetingRequest'
            : 'meetingRequests',
      ),
      1 => l10n.text('meetingCalendar'),
      _ => l10n.text('meetingSummary'),
    };

    final topPadding = MediaQuery.of(context).viewPadding.top;

    return ApiFilterScope(
      queries: {
        'meeting-requests': _filters[0].toQuery(),
        'meeting-summaries': _filters[2].toQuery(),
      },
      selections: {
        'meeting-requests': _filters[0],
        'meeting-summaries': _filters[2],
      },
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
                      if (_selectedTab == 1)
                        CalendarDateFilterButton(
                          selectedMonths: _calendarMonths,
                          onMonthsSelected: (months) => setState(() {
                            _calendarMonths = months;
                            _showCalendarMonthResults = months.isNotEmpty;
                          }),
                          selectedDate:
                              _calendarDate ??
                              DateUtils.dateOnly(DateTime.now()),
                          onSelected: (date) =>
                              setState(() => _calendarDate = date),
                        )
                      else
                        AppFilterButton(
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
                  0 =>
                    AppSettings.of(context).moduleType ==
                            AppModuleType.cdcSecretariat
                        ? const CdcMeetingRequestTab(
                            key: ValueKey('cdc-requests'),
                          )
                        : const MeetingRequestTab(key: ValueKey('requests')),
                  1 => CalendarTab(
                    selectedMonths: _calendarMonths,
                    showMonthResults: _showCalendarMonthResults,
                    key: const ValueKey('calendar'),
                    selectedDate: _calendarDate,
                    onDateSelected: (date) => setState(() {
                      _calendarDate = date;
                      _showCalendarMonthResults = false;
                    }),
                  ),
                  _ => MeetingSummaryTab(key: const ValueKey('summary')),
                },
              ),
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
        label:
            AppSettings.of(context).moduleType == AppModuleType.cdcSecretariat
            ? l10n.text('wgMeeting')
            : l10n.text('meetingCalendar'),
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
