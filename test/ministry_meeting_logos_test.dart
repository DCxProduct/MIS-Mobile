import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/issues/widgets/issue_agency_logo.dart';
import 'package:gpsf_app/features/shared/meetings/data/calendar_meeting.dart';
import 'package:gpsf_app/features/shared/meetings/data/meeting_request.dart';
import 'package:gpsf_app/features/shared/meetings/data/meeting_summary.dart';
import 'package:gpsf_app/features/private_sector/meetings/tabs/meeting_request_tab.dart'
    as private_sector;
import 'package:gpsf_app/screens/meeting/meeting_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final request = <String, dynamic>{
    'id': 4,
    'title': 'Request',
    'status': 'SUBMITTED',
    'user': {
      'stakeholders': [
        {
          'stakeholder': {'name': 'Tourism', 'logo': '/wrong-requester.png'},
        },
      ],
    },
    'governmentAgencies': [
      {
        'agencyOrder': 2,
        'stakeholder': {
          'id': 2,
          'name': 'Secondary',
          'logo': '/wrong-secondary.png',
        },
      },
      {
        'agencyOrder': 1,
        'stakeholder': {
          'id': 1,
          'name': 'MoT',
          'logo': '/uploads/request-logo.png',
        },
      },
    ],
  };
  final meeting = <String, dynamic>{
    'id': 22,
    'title': 'Calendar meeting',
    'meetingDate': '2026-10-19T00:00:00Z',
    'meetingRequest': {
      ...request,
      'governmentAgencies': [
        {
          'stakeholder': {
            'id': 1,
            'name': 'MoT',
            'logo': '/uploads/calendar-logo.png',
          },
        },
      ],
    },
  };
  final summary = <String, dynamic>{
    'id': 26,
    'summaryTitle': 'Summary',
    'governmentAgency': 'MoT',
    'governmentAgencyLogo': '/uploads/summary-logo.png',
  };

  test('each meeting model retains its responsible agency logo', () {
    expect(MeetingRequest(request).agencyLogo, '/uploads/request-logo.png');
    expect(
      CalendarMeeting.fromJson(meeting).details.agencyLogo,
      '/uploads/calendar-logo.png',
    );
    expect(MeetingSummary(summary).agencyLogo, '/uploads/summary-logo.png');
    expect(MeetingRequest({}).agencyLogo, isEmpty);
    expect(MeetingSummary({'id': 1}).agencyLogo, isEmpty);
    expect(
      MeetingSummary({
        'id': 1,
        'meetingRequest': {'governmentAgencyLogo': '/detail-logo.png'},
      }).agencyLogo,
      '/detail-logo.png',
    );
  });

  testWidgets('Private Sector request card and details use API agency logo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
      client: MockClient((call) async {
        expect(call.url.path, '/api/v1/meeting-requests');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [request],
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final settings = AppSettingsController(authRepository: AuthRepository(api))
      ..setLanguage(AppLanguage.english)
      ..setModuleType(AppModuleType.privateSector);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: private_sector.MeetingRequestTab(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    var logo = tester.widget<IssueAgencyLogo>(find.byType(IssueAgencyLogo));
    expect(logo.path, '/uploads/request-logo.png');
    expect(logo.size, 32);
    expect(logo.iconSize, 17);
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      'https://admin-mis-stage.datacolabx.com/uploads/request-logo.png',
    );
    await tester.tap(find.text('Request'));
    await tester.pumpAndSettle();
    logo = tester.widget<IssueAgencyLogo>(find.byType(IssueAgencyLogo));
    expect(logo.path, '/uploads/request-logo.png');
    expect(logo.size, 14);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all three Ministry tabs render API logos at their original sizes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((call) async {
                    final Object data = switch (call.url.path) {
                      '/api/v1/meeting-requests' => [request],
                      '/api/v1/meetings' => {
                        'items': [meeting],
                      },
                      '/api/v1/meeting-summaries' => {
                        'items': [summary],
                      },
                      _ => throw StateError('Unexpected API call ${call.url}'),
                    };
                    return http.Response(
                      jsonEncode({'success': true, 'data': data}),
                      200,
                    );
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
      var logo = tester.widget<IssueAgencyLogo>(find.byType(IssueAgencyLogo));
      expect(logo.path, '/uploads/request-logo.png');
      expect(logo.size, 34);
      await tester.ensureVisible(find.text('Meeting Calendar'));
      await tester.tap(find.text('Meeting Calendar'));
      await tester.pumpAndSettle();
      logo = tester.widget<IssueAgencyLogo>(find.byType(IssueAgencyLogo));
      expect(logo.path, '/uploads/calendar-logo.png');
      expect(logo.size, 34);
      await tester.ensureVisible(find.text('Meeting Summary'));
      await tester.tap(find.text('Meeting Summary'));
      await tester.pumpAndSettle();
      logo = tester.widget<IssueAgencyLogo>(find.byType(IssueAgencyLogo));
      expect(logo.path, '/uploads/summary-logo.png');
      expect(logo.size, 32);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://admin-mis-stage.datacolabx.com/uploads/summary-logo.png',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
