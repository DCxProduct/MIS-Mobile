import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/private_sector/meetings/tabs/calendar_tab.dart';
import 'package:gpsf_app/features/shared/meetings/widgets/monthly_meeting_calendar.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'month grid aligns weekdays, marks meetings, and switches language',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController()
        ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      var selected = DateTime(2026, 8, 1);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => MonthlyMeetingCalendar(
                  selectedDate: selected,
                  meetingDates: [
                    DateTime(2026, 8, 5),
                    DateTime(2026, 8, 6),
                    DateTime(2026, 8, 6),
                  ],
                  onSelected: (date) => setState(() => selected = date),
                ),
              ),
            ),
          ),
        ),
      );
      final first = find.byKey(const ValueKey('calendar-day-1'));
      final monday = find.byKey(const ValueKey('calendar-day-3'));
      expect(
        tester.getCenter(first).dx,
        greaterThan(tester.getCenter(monday).dx),
      );
      expect(tester.getCenter(first).dy, lessThan(tester.getCenter(monday).dy));
      expect(find.byKey(const ValueKey('calendar-dot-6-1')), findsOneWidget);
      final sunday = tester.widget<Text>(find.text('2'));
      expect(sunday.style!.color, const Color(0xFFF05B65));
      await tester.tap(find.byKey(const ValueKey('calendar-day-6')));
      await tester.pump();
      expect(selected, DateTime(2026, 8, 6));
      settings.setLanguage(AppLanguage.khmer);
      await tester.pump();
      expect(find.text('៦'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('calendar-month-title')))
            .data,
        contains('២០២៦'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('month navigation clamps leap day and crosses years', (
    tester,
  ) async {
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    var selected = DateTime(2024, 1, 31);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MonthlyMeetingCalendar(
                selectedDate: selected,
                meetingDates: const [],
                onSelected: (date) => setState(() => selected = date),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('calendar-next-month')));
    await tester.pump();
    expect(selected, DateTime(2024, 2, 29));
    expect(find.byKey(const ValueKey('calendar-day-29')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-day-30')), findsNothing);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('calendar-previous-month')));
      await tester.pump();
    }
    expect(selected, DateTime(2023, 12, 29));
    expect(tester.takeException(), isNull);
  });

  for (final scenario in [(false, null), (false, 1), (true, null)]) {
    final (empty, initialMeetingId) = scenario;
    testWidgets(
      'API calendar empty=$empty initialMeetingId=$initialMeetingId',
      (tester) async {
        final settings = AppSettingsController(
          authRepository: AuthRepository(
            ApiClient(
              client: MockClient((request) async {
                expect(request.url.path, '/api/v1/meetings');
                return http.Response(
                  jsonEncode({
                    'success': true,
                    'data': {
                      'items': empty
                          ? []
                          : [
                              {
                                'id': 1,
                                'title': 'First meeting',
                                'meetingDate': '2000-08-05T12:00:00',
                              },
                              {
                                'id': 2,
                                'title': 'Second meeting',
                                'meetingDate': '2000-08-06T12:00:00',
                              },
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
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: CalendarTab(
                    initialMeetingId: initialMeetingId,
                    detailBuilder: (meeting) =>
                        Scaffold(body: Text('Detail ${meeting.details.id}')),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(MonthlyMeetingCalendar), findsOneWidget);
        if (initialMeetingId != null) {
          expect(find.text('First meeting'), findsOneWidget);
          expect(find.text('Second meeting'), findsNothing);
          await tester.tap(find.byKey(const ValueKey('calendar-day-6')));
          await tester.pumpAndSettle();
          expect(find.text('First meeting'), findsNothing);
          expect(find.text('Second meeting'), findsOneWidget);
          await tester.ensureVisible(find.text('Second meeting'));
          await tester.tap(find.text('Second meeting'));
          await tester.pumpAndSettle();
          expect(find.text('Detail 2'), findsOneWidget);
        } else {
          final today = DateUtils.dateOnly(DateTime.now());
          expect(
            tester
                .widget<MonthlyMeetingCalendar>(
                  find.byType(MonthlyMeetingCalendar),
                )
                .selectedDate,
            today,
          );
          expect(find.text('First meeting'), findsNothing);
          expect(find.text('Second meeting'), findsNothing);
          await tester.tap(find.byKey(const ValueKey('calendar-next-month')));
          await tester.pumpAndSettle();
          expect(find.byType(MonthlyMeetingCalendar), findsOneWidget);
          final nextMonth = tester
              .widget<MonthlyMeetingCalendar>(
                find.byType(MonthlyMeetingCalendar),
              )
              .selectedDate;
          expect(
            DateTime(nextMonth.year, nextMonth.month),
            DateTime(today.year, today.month + 1),
          );
          settings.setLanguage(AppLanguage.khmer);
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<MonthlyMeetingCalendar>(
                  find.byType(MonthlyMeetingCalendar),
                )
                .selectedDate,
            nextMonth,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
