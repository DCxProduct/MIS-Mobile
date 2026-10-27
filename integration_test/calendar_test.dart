import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/private_sector/meetings/tabs/calendar_tab.dart';
import 'package:gpsf_app/features/shared/meetings/widgets/calendar_date_filter_button.dart';
import 'package:gpsf_app/features/shared/meetings/widgets/monthly_meeting_calendar.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mobile calendar: API pagination, dates, languages and layout', (
    tester,
  ) async {
    final pages = <int>[];
    final paths = <String>[];
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((request) async {
            paths.add(request.url.path);
            final page = int.parse(request.url.queryParameters['page']!);
            pages.add(page);
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'items': page == 1
                      ? [
                          {
                            'id': 1,
                            'title': 'December meeting',
                            'meetingDate': '2026-12-31T10:00:00',
                            'startTime': '2026-12-31T10:00:00',
                          },
                        ]
                      : [
                          {
                            'id': 2,
                            'title': 'January meeting A',
                            'meetingDate': '2027-01-01T09:00:00',
                            'startTime': '2027-01-01T09:00:00',
                          },
                          {
                            'id': 3,
                            'title': 'January meeting B',
                            'meetingDate': '2027-01-01T14:00:00',
                            'startTime': '2027-01-01T14:00:00',
                          },
                          {'id': 4, 'title': 'Undated meeting'},
                        ],
                  'meta': {'totalPages': 2},
                },
              }),
              200,
            );
          }),
        ),
      ),
    )..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    var selectedDate = DateTime(2026, 12, 31);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: AnimatedBuilder(
          animation: settings,
          builder: (context, _) => MaterialApp(
            locale: settings.locale,
            supportedLocales: const [Locale('en'), Locale('km')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            theme: ThemeData(
              fontFamily: settings.language == AppLanguage.khmer
                  ? 'KhBattambang'
                  : 'Times New Roman',
            ),
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                appBar: AppBar(
                  title: const Text('Calendar'),
                  actions: [
                    CalendarDateFilterButton(
                      selectedDate: selectedDate,
                      onSelected: (date) => setState(() => selectedDate = date),
                    ),
                    IconButton(
                      key: const ValueKey('language-switch'),
                      icon: const Icon(Icons.language),
                      onPressed: () => settings.setLanguage(
                        settings.language == AppLanguage.english
                            ? AppLanguage.khmer
                            : AppLanguage.english,
                      ),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: CalendarTab(
                      selectedDate: selectedDate,
                      onDateSelected: (date) =>
                          setState(() => selectedDate = date),
                      detailBuilder: (meeting) => Scaffold(
                        appBar: AppBar(),
                        body: Text('Meeting ${meeting.details.id}'),
                      ),
                    ),
                  ),
                ),
                bottomNavigationBar: const SizedBox(height: 64),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Device I/O can complete after the first frame has settled.
    for (
      var attempt = 0;
      attempt < 100 && find.byType(MonthlyMeetingCalendar).evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.byType(MonthlyMeetingCalendar),
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .join(' | '),
    );
    expect(pages, [1, 2]);
    expect(paths, everyElement('/api/v1/meetings'));
    expect(find.text('31 December 2026'), findsOneWidget);
    expect(find.text('December meeting'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendar-date-filter')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
    for (
      var attempt = 0;
      attempt < 100 &&
          find
              .byKey(const ValueKey('filter-local.month-2027-01'))
              .evaluate()
              .isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byKey(const ValueKey('filter-local.month-2027-01')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('1 January 2027'), findsOneWidget);
    expect(find.text('January meeting A'), findsOneWidget);
    expect(find.text('December meeting'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('calendar-date-filter')));
    await tester.pumpAndSettle();
    for (
      var attempt = 0;
      attempt < 100 &&
          find
              .byKey(const ValueKey('filter-local.month-2026-12'))
              .evaluate()
              .isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byKey(const ValueKey('filter-local.month-2026-12')));
    await tester.tap(find.byKey(const ValueKey('filter-local.month-2027-01')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-next-month')));
    await tester.pumpAndSettle();
    expect(find.text('31 January 2027'), findsOneWidget);
    expect(find.text('December meeting'), findsNothing);
    expect(find.byKey(const ValueKey('calendar-dot-1-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendar-day-1')));
    await tester.pumpAndSettle();
    expect(find.text('January meeting A'), findsOneWidget);
    expect(find.text('January meeting B'), findsOneWidget);
    expect(find.text('Undated meeting'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('language-switch')));
    await tester.pumpAndSettle();
    expect(find.text('១ មករា ២០២៧'), findsOneWidget);
    expect(find.text('ចន្ទ'), findsOneWidget);
    expect(find.text('Mon'), findsNothing);
    expect(pages, [
      1,
      2,
      1,
      2,
      1,
      2,
    ]); // Language switches must not refetch or reset the day.
    final context = tester.element(find.byType(MonthlyMeetingCalendar));
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('calendar-next-month')))
          .tooltip,
      MaterialLocalizations.of(context).nextMonthTooltip,
    );
    await tester.tap(find.byKey(const ValueKey('calendar-day-2')));
    await tester.pumpAndSettle();
    expect(find.text('January meeting A'), findsNothing);
    expect(
      find.text(
        AppLocalizations.of(
          context,
          page: 'meeting_calendar',
        ).text('noMeetings'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('calendar-previous-month')));
    await tester.pumpAndSettle();
    expect(find.text('២ ធ្នូ ២០២៦'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendar-day-31')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('December meeting'));
    await tester.tap(find.text('December meeting'));
    await tester.pumpAndSettle();
    expect(find.text('Meeting 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
