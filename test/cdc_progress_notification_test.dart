import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_secretariat/reports/progress_report_ministries_screen.dart';
import 'package:gpsf_app/features/shared/notifications/data/notification_destination.dart';
import 'package:gpsf_app/features/shared/notifications/data/system_notification.dart';
import 'package:gpsf_app/screens/notification/notification_screen.dart';
import 'package:gpsf_app/screens/report/report_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> submittedNotification({
  String type = 'PROGRESS_REPORT_SUBMITTED',
  Map<String, dynamic> data = const {'progressReportId': 2, 'ministryId': 1},
}) => {
  'id': 91,
  'type': type,
  'title': 'MoT',
  'message': 'Ministry progress report submitted: Actual report',
  'isRead': false,
  'createdAt': '2026-10-28T08:00:00Z',
  'data': data,
};

http.Response ok(Object data, {Map<String, dynamic>? meta}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode({'success': true, 'data': data, 'meta': ?meta})),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  for (final type in [
    'PROGRESS_REPORT_SUBMITTED',
    'PROGRESS_REPORT_RESUBMITTED',
    'PROGRESS_REPORT_MINISTRY_SUBMITTED',
    'PROGRESS_REPORT_MINISTRY_RESUBMITTED',
  ]) {
    test(
      '$type resolves CDC report and ministry independently of assignment ID',
      () {
        for (final url in [
          null,
          '/cdc-gpsf/progress-reports/2',
          '/cdc-gpsf/progress-reports/2/ministries/1',
          '/cdc-gpsf/progress-reports/2?ministryId=1',
        ]) {
          final destination = NotificationDestination.resolve(
            SystemNotification.fromJson(
              submittedNotification(
                type: type,
                data: {
                  'progressReportId': 2,
                  'ministryId': 1,
                  'assignmentId': 46,
                  'url': ?url,
                },
              ),
            ),
            AppModuleType.cdcSecretariat,
          );
          expect(
            destination?.kind,
            NotificationDestinationKind.cdcProgressReport,
          );
          expect(destination?.id, 2);
          expect(destination?.ministryId, 1);
          expect(destination?.endpoint, 'progress-reports/2/ministries/1');
        }
      },
    );
  }

  test(
    'parent-only notification opens CDC ministries and missing IDs stay unlinked',
    () {
      final destination = NotificationDestination.resolve(
        SystemNotification.fromJson(
          submittedNotification(data: {'progressReportId': 2}),
        ),
        AppModuleType.cdcSecretariat,
      );
      expect(destination?.id, 2);
      expect(destination?.ministryId, isNull);
      expect(destination?.endpoint, 'progress-reports/2');
      for (final data in <Map<String, dynamic>>[
        {},
        {'assignmentId': 46, 'ministryId': 1},
        {'progressReportId': 0},
        {'url': 'https://example.com/cdc-gpsf/progress-reports/2'},
        {'url': '/cdc-gpsf/progress-reports/2/ministries/0'},
        {'url': '/cdc-gpsf/progress-reports/2?ministryId=invalid'},
      ]) {
        expect(
          NotificationDestination.resolve(
            SystemNotification.fromJson(submittedNotification(data: data)),
            AppModuleType.cdcSecretariat,
          ),
          isNull,
        );
      }
      expect(
        NotificationDestination.resolve(
          SystemNotification.fromJson(submittedNotification()),
          AppModuleType.lineMinistry,
        ),
        isNull,
      );
    },
  );

  for (final entry in [
    (url: null, ministry: true, tapButton: true),
    (
      url: '/cdc-gpsf/progress-reports/2/ministries/1',
      ministry: true,
      tapButton: false,
    ),
    (url: '/cdc-gpsf/progress-reports/2', ministry: false, tapButton: true),
  ]) {
    testWidgets('CDC notification opens correct detail: $entry', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final calls = <String>[];
      final item = submittedNotification(
        data: {
          'progressReportId': 2,
          if (entry.ministry) 'ministryId': 1,
          'assignmentId': 46,
          'url': ?entry.url,
        },
      );
      final ministryDetail =
          (jsonDecode(
                    File(
                      'test/fixtures/cdc_ministry_progress_detail.json',
                    ).readAsStringSync(),
                  )
                  as Map<String, dynamic>)['data']
              as Map<String, dynamic>;
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    calls.add('${request.method} ${request.url.path}');
                    switch (request.url.path) {
                      case '/api/v1/mobile/system-notifications':
                        return ok(
                          [item],
                          meta: {
                            'page': 1,
                            'limit': 20,
                            'totalPages': 1,
                            'total': 1,
                            'unreadCount': 1,
                          },
                        );
                      case '/api/v1/mobile/system-notifications/91':
                        return ok(item);
                      case '/api/v1/notification-settings/me':
                        return ok({
                          'unreadBadge': true,
                          'markReadOnDetail': false,
                          'systemEnabled': true,
                        });
                      case '/api/v1/progress-reports/2/ministries/1':
                        return ok(ministryDetail);
                      case '/api/v1/progress-reports/2':
                        return ok(
                          ministryDetail['progressReport']
                              as Map<String, dynamic>,
                        );
                      case '/api/v1/progress-reports/2/ministries':
                        return ok([
                          {
                            'ministryId': 1,
                            'ministry': {'name': 'Actual submitting ministry'},
                            'status': 'SUBMITTED',
                            'issues': 3,
                          },
                        ]);
                      default:
                        fail(
                          'Unexpected request ${request.method} ${request.url}',
                        );
                    }
                  }),
                ),
              ),
            )
            ..setModuleType(AppModuleType.cdcSecretariat)
            ..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: NotificationScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('notification-detail-91')),
        findsOneWidget,
      );
      await tester.tap(
        entry.tapButton
            ? find.byKey(const ValueKey('notification-detail-91'))
            : find.text(item['message'] as String),
      );
      await tester.pumpAndSettle();
      if (entry.ministry) {
        expect(find.byType(ReportDetailScreen), findsOneWidget);
        final screen = tester.widget<ReportDetailScreen>(
          find.byType(ReportDetailScreen),
        );
        expect(screen.report?.details['progressReportId'], 2);
        expect(screen.report?.details['ministryId'], 1);
        expect(calls, contains('GET /api/v1/progress-reports/2/ministries/1'));
      } else {
        expect(find.byType(CdcProgressReportMinistriesScreen), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Actual submitting ministry'),
          300,
          scrollable: find
              .descendant(
                of: find.byType(CdcProgressReportMinistriesScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.text('Actual submitting ministry'), findsOneWidget);
        expect(calls, contains('GET /api/v1/progress-reports/2/ministries'));
      }
      expect(calls, contains('GET /api/v1/mobile/system-notifications/91'));
      expect(calls.any((call) => call.contains('/ministries/me')), isFalse);
      expect(calls.any((call) => call.startsWith('PATCH')), isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
