import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/widgets/filters/app_filter_sheet.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/private_sector/meetings/tabs/calendar_tab.dart';
import 'package:gpsf_app/features/shared/meetings/widgets/calendar_date_filter_button.dart';
import 'package:gpsf_app/features/shared/meetings/widgets/monthly_meeting_calendar.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final failFirst in [false, true]) {
    testWidgets('API month/year filter handles empty and retry: $failFirst', (
      tester,
    ) async {
      var requests = 0;
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((_) async {
              requests++;
              if (failFirst && requests == 1) return http.Response('{}', 500);
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'items': failFirst
                        ? [
                            {'id': 1, 'meetingDate': '2029-06-10T12:00:00'},
                          ]
                        : [
                            {'id': 2, 'title': 'Undated'},
                          ],
                  },
                }),
                200,
              );
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      DateTime? result;
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: CalendarDateFilterButton(
                selectedDate: DateTime(2026, 10, 27),
                onSelected: (date) => result = date,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('calendar-date-filter')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('filter-local.month-2026-12')),
        findsNothing,
      );
      expect(find.byType(FilledButton), findsNothing);
      if (failFirst) {
        await tester.tap(find.widgetWithText(TextButton, 'Retry'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('filter-local.month-2029-06')),
        );
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(result, DateTime(2029, 6, 10));
      } else {
        expect(find.text('No meetings found.'), findsOneWidget);
        expect(result, isNull);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in AppLanguage.values) {
    testWidgets('month/year filter updates calendar and meetings in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var requests = 0;
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              requests++;
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'items': request.url.queryParameters['page'] == '1'
                        ? []
                        : [
                            {
                              'id': 1,
                              'title': 'December meeting',
                              'meetingDate': '2026-12-31T09:00:00',
                            },
                            {
                              'id': 2,
                              'title': 'Next year meeting',
                              'meetingDate': '2027-01-01T09:00:00',
                            },
                            {'id': 3, 'title': 'Undated meeting'},
                            {'id': 4, 'meetingDate': '2027-01-01T14:00:00'},
                            {
                              'id': 5,
                              'title': 'February meeting',
                              'meetingDate': '2027-02-14T09:00:00',
                            },
                          ],
                    'meta': {'totalPages': 2},
                  },
                }),
                200,
              );
            }),
          ),
        ),
      )..setLanguage(language);
      addTearDown(settings.dispose);
      var selected = DateTime(2026, 12, 31);
      Set<String> months = {};
      var showMonths = false;
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            locale: settings.locale,
            supportedLocales: const [Locale('en'), Locale('km')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  void select(DateTime date) => setState(() => selected = date);
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        CalendarDateFilterButton(
                          selectedMonths: months,
                          onMonthsSelected: (value) => setState(() {
                            months = value;
                            showMonths = value.isNotEmpty;
                          }),
                          selectedDate: selected,
                          onSelected: select,
                        ),
                        CalendarTab(
                          selectedMonths: months,
                          showMonthResults: showMonths,
                          selectedDate: selected,
                          onDateSelected: (date) => setState(() {
                            selected = date;
                            showMonths = false;
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('December meeting'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-date-filter')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(
        find.text(language == AppLanguage.khmer ? 'មករា ២០២៧' : 'Jan 2027'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('filter-local.month-2028-01')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('filter-local.month-2027-01')),
      );
      await tester.pumpAndSettle();
      expect(selected, DateTime(2026, 12, 31));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(selected, DateTime(2027, 1, 1));
      expect(find.text('Next year meeting'), findsOneWidget);
      expect(find.text('December meeting'), findsNothing);
      expect(
        tester
            .widget<MonthlyMeetingCalendar>(find.byType(MonthlyMeetingCalendar))
            .selectedDate,
        selected,
      );

      // Grid selections are reflected in the next picker, including cancellation.
      await tester.tap(find.byKey(const ValueKey('calendar-day-2')));
      await tester.pumpAndSettle();
      expect(find.text('Next year meeting'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('calendar-date-filter')));
      await tester.pumpAndSettle();
      final pickerContext = tester.element(
        find.byKey(const ValueKey('calendar-month-filter-sheet')),
      );
      final labels = MaterialLocalizations.of(pickerContext);
      expect(
        tester
            .widget<AppFilterSheet>(find.byType(AppFilterSheet))
            .initial['local.month'],
        {'2027-01'},
      );
      await tester.tap(
        find.byKey(const ValueKey('filter-local.month-2026-12')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(labels.closeButtonTooltip));
      await tester.pumpAndSettle();
      expect(selected, DateTime(2027, 1, 2));
      expect(requests, 6);
      await tester.tap(find.byKey(const ValueKey('calendar-date-filter')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('filter-local.month-2027-01')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('filter-local.month-2027-03')),
        findsNothing,
      );
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('filter-local.month-2027-02')),
            )
            .dx,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('filter-local.month-2027-01')),
              )
              .dx,
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('filter-local.month-2027-02')),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(months, {'2027-01', '2027-02'});
      expect(find.text('February meeting'), findsOneWidget);
      expect(find.text('Next year meeting'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-date-filter')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppFilterSheet>(find.byType(AppFilterSheet))
            .initial['local.month'],
        {'2027-01', '2027-02'},
      );
      await tester.tap(
        find.byKey(const ValueKey('filter-local.month-2027-01')),
      );
      await tester.tap(
        find.byKey(const ValueKey('filter-local.month-2027-02')),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(months, isEmpty);
      expect(selected, DateUtils.dateOnly(DateTime.now()));
      expect(
        tester
            .widget<MonthlyMeetingCalendar>(find.byType(MonthlyMeetingCalendar))
            .selectedDate,
        DateUtils.dateOnly(DateTime.now()),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
