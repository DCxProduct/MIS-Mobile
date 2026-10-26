import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';

/// A Monday-first calendar. Dates and meeting markers use local calendar days.
class MonthlyMeetingCalendar extends StatelessWidget {
  const MonthlyMeetingCalendar({
    super.key,
    required this.selectedDate,
    required this.meetingDates,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final List<DateTime> meetingDates;
  final ValueChanged<DateTime> onSelected;

  static const _weekend = Color(0xFFF05B65);

  void _changeMonth(int offset) {
    final start = DateTime(selectedDate.year, selectedDate.month + offset);
    final lastDay = DateTime(start.year, start.month + 1, 0).day;
    onSelected(
      DateTime(
        start.year,
        start.month,
        selectedDate.day > lastDay ? lastDay : selectedDate.day,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context, page: 'meeting_calendar');
    final start = DateTime(selectedDate.year, selectedDate.month);
    final days = DateTime(start.year, start.month + 1, 0).day;
    final offset = start.weekday - DateTime.monday;
    final weeks = (offset + days + 6) ~/ 7;
    final counts = <int, int>{};
    for (final raw in meetingDates) {
      final date = raw.toLocal();
      if (date.year == start.year && date.month == start.month) {
        counts.update(date.day, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('calendar-previous-month'),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).previousMonthTooltip,
                  onPressed: () => _changeMonth(-1),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    minimumSize: const Size(44, 44),
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${l10n.number(selectedDate.day)} ${_monthName(context, start.month)} ${l10n.number(start.year)}',
                      key: const ValueKey('calendar-month-title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('calendar-next-month'),
                  tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                  onPressed: () => _changeMonth(1),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    minimumSize: const Size(44, 44),
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    for (var weekday = 1; weekday <= 7; weekday++)
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _weekday(context, weekday),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: weekday >= 6 ? _weekend : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                for (var week = 0; week < weeks; week++)
                  Row(
                    children: [
                      for (var column = 0; column < 7; column++)
                        Expanded(
                          child: SizedBox(
                            height: 52 * scale,
                            child: _day(
                              context,
                              week * 7 + column - offset + 1,
                              days,
                              column >= 5,
                              counts,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _day(
    BuildContext context,
    int day,
    int days,
    bool weekend,
    Map<int, int> counts,
  ) {
    if (day < 1 || day > days) return const SizedBox.shrink();
    final selected = day == selectedDate.day;
    final date = DateTime(selectedDate.year, selectedDate.month, day);
    final count = counts[day] ?? 0;
    return Semantics(
      selected: selected,
      button: true,
      label: AppLocalizations.of(context).date(date),
      child: InkWell(
        key: ValueKey('calendar-day-$day'),
        borderRadius: BorderRadius.circular(22),
        onTap: () => onSelected(date),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.accent(context) : null,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppLocalizations.of(context).number(day),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected
                        ? Colors.white
                        : weekend
                        ? _weekend
                        : null,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < count && i < 3; i++)
                    Container(
                      key: ValueKey('calendar-dot-$day-$i'),
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.accent(context),
                        shape: BoxShape.circle,
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

  static String _monthName(BuildContext context, int month) {
    const codes = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    return _name(context, 'months', 'month', codes[month - 1]);
  }

  static String _weekday(BuildContext context, int weekday) {
    const codes = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return _name(context, 'weekdays', 'weekday', codes[weekday - 1]);
  }

  static String _name(
    BuildContext context,
    String group,
    String prefix,
    String code,
  ) {
    final l10n = AppLocalizations.of(context, page: 'meeting_calendar');
    return l10n.api(
      'meeting_requests.calendar_ui.$group.$code',
      fallback: l10n.text(
        '$prefix${code[0].toUpperCase()}${code.substring(1)}',
      ),
    );
  }
}
