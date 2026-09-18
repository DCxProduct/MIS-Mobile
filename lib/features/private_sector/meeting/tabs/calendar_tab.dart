import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';

class CalendarTab extends StatelessWidget {
  const CalendarTab({super.key});

  static const _month = 'July';
  static const _year = '2026';
  static const _selectedDay = 9;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            '$_month $_year',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          const _FullMonthCalendar(),
          const SizedBox(height: 18),
          _CalendarEventCard(
            title: l10n.text('calendarEventOne'),
            attendees: '15',
            time: '2:00PM-5:00PM',
            color: const Color(0xFF20B8A9),
          ),
          _CalendarEventCard(
            title: l10n.text('calendarEventTwo'),
            attendees: '9',
            time: '2:00PM-5:00PM',
            color: const Color(0xFFFF9C7B),
          ),
          _CalendarEventCard(
            title: l10n.text('calendarEventThree'),
            attendees: '10',
            time: '8:00AM-5:00PM',
            color: AppColors.primary,
          ),
          _CalendarEventCard(
            title: l10n.text('calendarEventFour'),
            attendees: '6',
            time: '3:00PM-4:00PM',
            color: const Color(0xFFFF9A4A),
          ),
        ],
      ),
    );
  }
}

class _FullMonthCalendar extends StatelessWidget {
  const _FullMonthCalendar();

  static const _weekdays = ['Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue'];

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
          itemCount: 31,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final day = index + 1;
            final selected = day == CalendarTab._selectedDay;
            return SizedBox(
              width: 36,
              child: Column(
                children: [
                  Text(
                    _weekdays[index % _weekdays.length],
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
                      '$day',
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
            );
          },
        ),
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({
    required this.title,
    required this.attendees,
    required this.time,
    required this.color,
  });

  final String title;
  final String attendees;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                          attendees,
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
                          time,
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
    );
  }
}
