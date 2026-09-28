import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';
import '../../../shared/meetings/data/calendar_meeting.dart';
import '../../../shared/meetings/widgets/meetings_loader.dart';
import '../meeting_request_detail_screen.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : Colors.white,
      child: MeetingsLoader(
        builder: (meetings) => _buildCalendar(context, meetings),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, List<CalendarMeeting> meetings) {
    final datedMeetings =
        meetings.where((meeting) => meeting.date != null).toList()
          ..sort((a, b) => a.date!.compareTo(b.date!));
    if (datedMeetings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(AppLocalizations.of(context).text('noMeetings')),
      );
    }

    final firstDate = datedMeetings.first.date!.toLocal();
    final selected = _selectedDate == null
        ? DateTime(firstDate.year, firstDate.month, firstDate.day)
        : DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          );
    final monthMeetings = datedMeetings
        .where((meeting) => _sameMonth(meeting.date!.toLocal(), selected))
        .toList();
    final selectedMeetings = monthMeetings
        .where((meeting) => _sameDay(meeting.date!.toLocal(), selected))
        .toList();
    final monthStart = DateTime(selected.year, selected.month, 1);
    final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          '${_monthName(selected.month)} ${selected.year}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _CalendarDays(
          monthStart: monthStart,
          daysInMonth: daysInMonth,
          selectedDate: selected,
          meetingDates: monthMeetings
              .map((meeting) => meeting.date!.toLocal())
              .toList(),
          onSelected: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 18),
        if (selectedMeetings.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              AppLocalizations.of(context).text('noMeetings'),
              style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
          )
        else
          for (final meeting in selectedMeetings)
            _CalendarEventCard(
              meeting: meeting,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MeetingRequestDetailScreen(
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

  static String _monthName(int month) => const [
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
    'December',
  ][month - 1];
}

class _CalendarDays extends StatelessWidget {
  const _CalendarDays({
    required this.monthStart,
    required this.daysInMonth,
    required this.selectedDate,
    required this.meetingDates,
    required this.onSelected,
  });

  final DateTime monthStart;
  final int daysInMonth;
  final DateTime selectedDate;
  final List<DateTime> meetingDates;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border(context))),
      ),
      child: SizedBox(
        height: 58,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: daysInMonth,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final date = DateTime(monthStart.year, monthStart.month, index + 1);
            final selected = _sameDay(date, selectedDate);
            return SizedBox(
              width: 36,
              child: InkWell(
                onTap: () => onSelected(date),
                borderRadius: BorderRadius.circular(6),
                child: Column(
                  children: [
                    Text(
                      _weekday(date.weekday),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF9AA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _weekday(int weekday) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
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
                            '${meeting.guestCount}',
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
                            _timeLabel(meeting.startTime),
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

  static String _timeLabel(DateTime? time) {
    if (time == null) return '—';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
  }
}
