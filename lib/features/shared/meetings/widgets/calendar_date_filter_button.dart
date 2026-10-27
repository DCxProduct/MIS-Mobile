import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/app_settings.dart';
import '../../../../core/widgets/filters/api_filter_scope.dart';
import '../../../../core/widgets/filters/app_filter_button.dart';
import '../../../../core/widgets/filters/app_filter_sheet.dart';
import '../../../../core/widgets/filters/filter_sheet_header.dart';
import '../../../../translations/app_localizations.dart';
import '../../../../translations/app_language.dart';

String _monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

String _monthLabel(AppLocalizations l10n, DateTime date) {
  const keys = [
    'monthJan',
    'monthFeb',
    'monthMar',
    'monthApr',
    'monthMay',
    'monthJun',
    'monthJul',
    'monthAug',
    'monthSep',
    'monthOct',
    'monthNov',
    'monthDec',
  ];
  final month = l10n.text(keys[date.month - 1]);
  final label = l10n.language == AppLanguage.english
      ? month.substring(0, 3)
      : month;
  return '$label ${l10n.number(date.year)}';
}

/// Shows only month/year pairs represented by dated meetings from every API page.
class CalendarDateFilterButton extends StatefulWidget {
  const CalendarDateFilterButton({
    super.key,
    required this.selectedDate,
    required this.onSelected,
    this.selectedMonths,
    this.onMonthsSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final Set<String>? selectedMonths;
  final ValueChanged<Set<String>>? onMonthsSelected;

  @override
  State<CalendarDateFilterButton> createState() =>
      _CalendarDateFilterButtonState();
}

class _CalendarDateFilterButtonState extends State<CalendarDateFilterButton> {
  Set<String> _months = {};
  Set<String> get _applied => widget.selectedMonths ?? _months;

  Future<void> _openFilter(BuildContext context) async {
    final repository = AppSettings.of(context).meetings;
    final query = ApiFilterScope.query(context, 'meetings');
    var dates = <DateTime>[];
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CalendarMonthFilterSheet(
          initialMonths: _applied,
          load: () async {
            final meetings = await repository.getMeetings(filters: query);
            dates =
                meetings
                    .where((meeting) => meeting.date != null)
                    .map(
                      (meeting) => DateUtils.dateOnly(meeting.date!.toLocal()),
                    )
                    .toSet()
                    .toList()
                  ..sort();
            return dates;
          },
        ),
      ),
    );
    if (!context.mounted || result == null) return;
    final months = Set<String>.of(result['local.month']);
    setState(() => _months = months);
    widget.onMonthsSelected?.call(months);
    if (months.isEmpty) {
      widget.onSelected(DateUtils.dateOnly(DateTime.now()));
      return;
    }
    final matches = dates
        .where((date) => months.contains(_monthKey(date)))
        .toList();
    if (matches.isEmpty) return;
    // Keep the selected day if it has meetings; otherwise open the first
    // meeting in the chosen month so applying the filter shows actual data.
    widget.onSelected(
      matches.firstWhere(
        (date) => DateUtils.isSameDay(date, widget.selectedDate),
        orElse: () => matches.first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppFilterButton(
    key: const ValueKey('calendar-date-filter'),
    activeCount: _applied.length,
    onTap: () => _openFilter(context),
  );
}

class _CalendarMonthFilterSheet extends StatefulWidget {
  const _CalendarMonthFilterSheet({
    required this.load,
    required this.initialMonths,
  });

  final Future<List<DateTime>> Function() load;
  final Set<String> initialMonths;

  @override
  State<_CalendarMonthFilterSheet> createState() =>
      _CalendarMonthFilterSheetState();
}

class _CalendarMonthFilterSheetState extends State<_CalendarMonthFilterSheet> {
  late Future<List<DateTime>> _request = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<DateTime>>(
    future: _request,
    builder: (context, snapshot) {
      final l10n = AppLocalizations.of(context, page: 'meeting_calendar');
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData &&
          snapshot.data!.isNotEmpty) {
        final months =
            snapshot.data!
                .map((date) => DateTime(date.year, date.month))
                .toSet()
                .toList()
              ..sort((a, b) => b.compareTo(a));
        return AppFilterSheet(
          key: const ValueKey('calendar-month-filter-sheet'),
          compact: true,
          initial: FilterSelection({'local.month': widget.initialMonths}),
          // Closing discards the draft. Only Apply changes the calendar.
          onClose: () => Navigator.pop(context),
          sections: [
            FilterSection(
              id: 'local.month',
              title: l10n.text('meetingDate'),
              columns: 2,
              collapsedItemCount: 10,
              options: [
                for (final month in months)
                  FilterOption(
                    value: _monthKey(month),
                    label: _monthLabel(l10n, month),
                  ),
              ],
            ),
          ],
        );
      }
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              FilterSheetHeader(
                title: l10n.text('filters'),
                onClose: () => Navigator.pop(context),
                titleStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Divider(height: 1, color: AppColors.border(context)),
              Expanded(
                child: Center(
                  child: snapshot.connectionState != ConnectionState.done
                      ? const CircularProgressIndicator()
                      : snapshot.hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.text('meetingsLoadError')),
                            TextButton(
                              onPressed: () => setState(() {
                                _request = widget.load();
                              }),
                              child: Text(l10n.text('retry')),
                            ),
                          ],
                        )
                      : Text(l10n.text('noMeetings')),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
