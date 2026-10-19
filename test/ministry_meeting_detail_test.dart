import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/line_ministry/meetings/meeting_detail_screen.dart';
import 'package:gpsf_app/features/shared/meetings/data/calendar_meeting.dart';
import 'package:gpsf_app/features/shared/meetings/data/meeting_request.dart';
import 'package:gpsf_app/features/shared/meetings/data/meetings_repository.dart';
import 'package:gpsf_app/screens/meeting/meeting_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final detail = <String, dynamic>{
    'id': 22,
    'title': 'Actual ministry meeting',
    'status': 'COMPLETED',
    'description': '<p>Actual meeting description</p>',
    'createdAt': '2026-10-19T09:00:00Z',
    'meetingDate': '2026-10-20T00:00:00Z',
    'workingGroupName': 'Tourism',
    'user': {'name': 'Actual submitter'},
    'receivedBy': {'id': 7, 'name': 'Actual receiver'},
    'documentReference': {
      'path': '/uploads/actual_meeting.pdf',
      'name': 'Actual meeting.pdf',
      'size': 4096,
    },
    'governmentAgencies': [
      {
        'stakeholder': {'id': 1, 'name': 'MoT'},
      },
    ],
    'issues': [
      {'id': 8, 'title': 'Direct API issue'},
    ],
    'meetingRequest': {
      'issues': [
        {'id': 8, 'title': 'Duplicate issue'},
        {
          'id': 9,
          'title': 'Linked API issue',
          'description': '<p>Actual issue description</p>',
          'recommendation': '<p>Actual recommendation</p>',
          'issueStatus': {'code': 'SOLVED', 'name': 'Solved'},
        },
      ],
    },
  };

  http.Response ok(Object data) => http.Response(
    jsonEncode({'success': true, 'data': data}),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  test(
    'receiver uses API names and supports linked requests when absent on meeting',
    () {
      for (final value in [
        ' Actual receiver ',
        {'name': 'Actual receiver'},
      ]) {
        expect(
          MeetingRequest({'receivedBy': value}).receivedBy,
          'Actual receiver',
        );
      }
      for (final value in [
        null,
        '',
        '  ',
        7,
        {'id': 7},
      ]) {
        expect(MeetingRequest({'receivedBy': value}).receivedBy, isEmpty);
      }
      final linked = CalendarMeeting.fromJson({
        'id': 22,
        'meetingRequest': {
          'receivedBy': {'name': 'Linked receiver'},
        },
      });
      expect(linked.details.receivedBy, 'Linked receiver');
      expect(
        CalendarMeeting.fromJson(detail).details.receivedBy,
        'Actual receiver',
      );
    },
  );

  test(
    'meeting detail preserves direct and linked data without duplicates',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/meetings/22');
          return ok(detail);
        }),
      );
      addTearDown(api.close);
      final meeting = await MeetingsRepository(api).getMeeting(22);
      expect(meeting.details.group, 'Tourism');
      expect(meeting.details.submittedBy, 'Actual submitter');
      expect(meeting.details.submittedAt, DateTime.utc(2026, 10, 19, 9));
      expect(meeting.details.agencies, 'MoT');
      expect(meeting.details.issues.map((issue) => issue.title), [
        'Direct API issue',
        'Linked API issue',
      ]);
      expect(meeting.details.letterSize, 4096);
    },
  );

  for (final calendar in [false, true]) {
    testWidgets(
      '${calendar ? 'calendar' : 'list'} opens selected meeting API detail',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final calls = <String>[];
        final settings =
            AppSettingsController(
                authRepository: AuthRepository(
                  ApiClient(
                    client: MockClient((request) async {
                      calls.add(request.url.path);
                      switch (request.url.path) {
                        case '/api/v1/meeting-requests':
                          return ok([]);
                        case '/api/v1/meetings':
                          return ok({
                            'items': [
                              {
                                'id': 22,
                                'title': 'List meeting title',
                                'meetingDate': '2026-10-20T00:00:00Z',
                              },
                            ],
                          });
                        case '/api/v1/meetings/22':
                          return ok(detail);
                        default:
                          throw StateError('Unexpected request ${request.url}');
                      }
                    }),
                  ),
                ),
              )
              ..setLanguage(AppLanguage.english)
              ..setModuleType(AppModuleType.lineMinistry);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: const MaterialApp(home: Scaffold(body: MeetingScreen())),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Meeting Calendar'));
        await tester.pumpAndSettle();
        if (calendar) {
          await tester.tap(find.byIcon(Icons.calendar_month_rounded));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('List meeting title'));
        await tester.pumpAndSettle();
        expect(find.text('Actual ministry meeting'), findsOneWidget);
        expect(find.text('Actual meeting description'), findsOneWidget);
        expect(find.text('Actual meeting.pdf'), findsOneWidget);
        expect(find.text('MoT'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(
          find.text('Received By : Actual receiver', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Sabada'), findsNothing);
        expect(find.text('PSWG-A'), findsNothing);
        final preview = tester.widget<PdfAttachmentPreview>(
          find.byType(PdfAttachmentPreview),
        );
        expect(preview.path, '/uploads/actual_meeting.pdf');
        settings.setLanguage(AppLanguage.khmer);
        await tester.pumpAndSettle();
        final km = AppLocalizations(AppLanguage.khmer);
        expect(find.text(km.text('completed')), findsOneWidget);
        expect(
          find.text(
            '${km.text('receivedBy')} : Actual receiver',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(
          calls.where((path) => path == '/api/v1/meetings/22'),
          hasLength(1),
        );
        await tester.tap(find.text(km.text('allIssues')));
        await tester.pumpAndSettle();
        expect(find.text('Direct API issue'), findsOneWidget);
        expect(find.text('Linked API issue'), findsOneWidget);
        expect(find.text('Duplicate issue'), findsNothing);
        await tester.tap(find.text('Linked API issue'));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('Actual issue description', findRichText: true),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('failed or mismatched detail retries without showing demo data', (
    tester,
  ) async {
    var calls = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((_) async {
            calls++;
            if (calls == 1) return http.Response('{}', 500);
            return ok({
              ...detail,
              'id': calls == 2 ? 99 : 22,
              'receivedBy': null,
            });
          }),
        ),
      ),
    )..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(
          home: LineMinistryMeetingDetailScreen(meetingId: 22),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var attempt = 0; attempt < 2; attempt++) {
      expect(find.text('Unable to load meetings.'), findsOneWidget);
      expect(find.text('Actual ministry meeting'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Actual ministry meeting'), findsOneWidget);
    expect(
      find.textContaining('Received By', findRichText: true),
      findsNothing,
    );
    expect(calls, 3);
    expect(tester.takeException(), isNull);
  });
}
