import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/app_settings.dart';
import '../../../../core/widgets/filters/api_filter_scope.dart';
import '../../../../core/widgets/filters/app_filter_button.dart';
import '../../../../core/widgets/filters/app_filter_sheet.dart';
import '../../../../core/widgets/filters/filter_sheet_header.dart';
import '../../../../translations/app_localizations.dart';
import '../../../../translations/app_language.dart';
import '../data/calendar_meeting.dart';

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
    this.showMinistryFilter = false,
    this.selectedMinistries = const {},
    this.onMinistriesSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final Set<String>? selectedMonths;
  final ValueChanged<Set<String>>? onMonthsSelected;
  final bool showMinistryFilter;
  final Set<String> selectedMinistries;
  final ValueChanged<Set<String>>? onMinistriesSelected;

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
    var meetings = <CalendarMeeting>[];
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CalendarMonthFilterSheet(
          initialMonths: _applied,
          showMinistryFilter: widget.showMinistryFilter,
          initialMinistries: widget.selectedMinistries,
          load: () async {
            meetings = await repository.getMeetings(filters: query);
            return meetings;
          },
        ),
      ),
    );
    if (!context.mounted || result == null) return;
    final months = Set<String>.of(result['local.month']);
    final ministries = Set<String>.of(result['local.primaryAgency']);
    setState(() => _months = months);
    widget.onMonthsSelected?.call(months);
    if (widget.showMinistryFilter) {
      widget.onMinistriesSelected?.call(ministries);
    }
    if (months.isEmpty && ministries.isEmpty) {
      widget.onSelected(DateUtils.dateOnly(DateTime.now()));
      return;
    }
    final selection = FilterSelection({'local.primaryAgency': ministries});
    final matches =
        meetings
            .where(
              (meeting) =>
                  meeting.date != null &&
                  selection.matchesLocal(meeting.details.filterValues),
            )
            .map((meeting) => DateUtils.dateOnly(meeting.date!.toLocal()))
            .where((date) => months.isEmpty || months.contains(_monthKey(date)))
            .toSet()
            .toList()
          ..sort();
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
    activeCount:
        _applied.length +
        (widget.showMinistryFilter ? widget.selectedMinistries.length : 0),
    onTap: () => _openFilter(context),
  );
}

class _CalendarMonthFilterSheet extends StatefulWidget {
  const _CalendarMonthFilterSheet({
    required this.load,
    required this.initialMonths,
    required this.showMinistryFilter,
    required this.initialMinistries,
  });

  final Future<List<CalendarMeeting>> Function() load;
  final Set<String> initialMonths;
  final bool showMinistryFilter;
  final Set<String> initialMinistries;

  @override
  State<_CalendarMonthFilterSheet> createState() =>
      _CalendarMonthFilterSheetState();
}

class _CalendarMonthFilterSheetState extends State<_CalendarMonthFilterSheet> {
  late Future<List<CalendarMeeting>> _request = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<CalendarMeeting>>(
    future: _request,
    builder: (context, snapshot) {
      final l10n = AppLocalizations.of(context, page: 'meeting_calendar');
      final dates = (snapshot.data ?? const <CalendarMeeting>[])
          .where((meeting) => meeting.date != null)
          .map((meeting) => meeting.date!.toLocal())
          .toList();
      final ministries =
          (snapshot.data ?? const <CalendarMeeting>[])
              .expand((meeting) => meeting.details.agencyNames)
              .where((name) => name.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData &&
          (dates.isNotEmpty ||
              (widget.showMinistryFilter && ministries.isNotEmpty))) {
        final months =
            dates
                .map((date) => DateTime(date.year, date.month))
                .toSet()
                .toList()
              ..sort((a, b) => b.compareTo(a));
        return AppFilterSheet(
          key: const ValueKey('calendar-month-filter-sheet'),
          compact: true,
          initial: FilterSelection({
            'local.month': widget.initialMonths,
            if (widget.showMinistryFilter)
              'local.primaryAgency': widget.initialMinistries,
          }),
          // Closing discards the draft. Only Apply changes the calendar.
          onClose: () => Navigator.pop(context),
          sections: [
            if (widget.showMinistryFilter)
              FilterSection(
                id: 'local.primaryAgency',
                title: l10n.text('ministry'),
                columns: 3,
                collapsedItemCount: 9,
                options: [
                  for (final ministry in ministries)
                    FilterOption(value: ministry, label: ministry),
                ],
              ),
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
