import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';
import '../../../shared/meetings/data/calendar_meeting.dart';
import '../../../shared/meetings/widgets/meetings_loader.dart';
import '../../../shared/meetings/widgets/monthly_meeting_calendar.dart';
import '../meeting_request_detail_screen.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({
    super.key,
    this.initialMeetingId,
    this.detailBuilder,
    this.selectedDate,
    this.onDateSelected,
    this.selectedMonths = const {},
    this.showMonthResults = false,
  });

  final int? initialMeetingId;
  final Widget Function(CalendarMeeting meeting)? detailBuilder;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final Set<String> selectedMonths;
  final bool showMonthResults;

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return MeetingsLoader(
      buildWhenEmpty: true,
      builder: (meetings) => _buildCalendar(context, meetings),
    );
  }

  Widget _buildCalendar(BuildContext context, List<CalendarMeeting> meetings) {
    final datedMeetings = meetings.where((meeting) {
      final date = meeting.date?.toLocal();
      return date != null &&
          (widget.selectedMonths.isEmpty ||
              widget.selectedMonths.contains(
                '${date.year}-${date.month.toString().padLeft(2, '0')}',
              ));
    }).toList()..sort((a, b) => a.date!.compareTo(b.date!));
    if (_selectedDate == null && widget.initialMeetingId != null) {
      for (final meeting in datedMeetings) {
        if (meeting.details.id == widget.initialMeetingId) {
          _selectedDate = meeting.date!.toLocal();
          break;
        }
      }
    }
    // Open on the device's current day, not the oldest API meeting.
    // An explicitly opened meeting or a user's date selection takes priority.
    final date = widget.selectedDate ?? _selectedDate ?? DateTime.now();
    final selected = DateTime(date.year, date.month, date.day);
    final monthMeetings = datedMeetings
        .where((meeting) => _sameMonth(meeting.date!.toLocal(), selected))
        .toList();
    final selectedMeetings =
        widget.showMonthResults && widget.selectedMonths.isNotEmpty
        ? datedMeetings
        : monthMeetings
              .where((meeting) => _sameDay(meeting.date!.toLocal(), selected))
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonthlyMeetingCalendar(
          selectedDate: selected,
          meetingDates: monthMeetings
              .map((meeting) => meeting.date!.toLocal())
              .toList(),
          onSelected: (date) {
            setState(() => _selectedDate = date);
            widget.onDateSelected?.call(date);
          },
        ),
        const SizedBox(height: 18),
        if (selectedMeetings.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              AppLocalizations.of(
                context,
                page: 'meeting_calendar',
              ).text('calendarNoMeetings'),
              style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
          )
        else
          for (final meeting in selectedMeetings)
            _CalendarEventCard(
              meeting: meeting,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      widget.detailBuilder?.call(meeting) ??
                      MeetingRequestDetailScreen(
                        translationPage: 'meeting_calendar',
                        title: meeting.details.title,
                        request: meeting.details,
                      ),
                ),
              ),
            ),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.meeting, required this.onTap});

  final CalendarMeeting meeting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFEDEFF3),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: AppColors.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.details.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            color: AppColors.mutedText,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(
                              context,
                            ).number(meeting.guestCount),
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.mutedText,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            AppLocalizations.of(
                              context,
                            ).time(meeting.startTime),
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
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
